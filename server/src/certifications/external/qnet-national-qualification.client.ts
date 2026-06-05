import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { XMLParser } from 'fast-xml-parser';

export type QnetNationalQualificationItem = {
  qualgbcd?: string;
  qualgbnm?: string;
  seriescd?: string;
  seriesnm?: string;
  jmcd: string;
  jmfldnm: string;
  obligfldcd?: string;
  obligfldnm?: string;
  mdobligfldcd?: string;
  mdobligfldnm?: string;
  [key: string]: unknown;
};

type QnetListResponse = {
  response?: {
    header?: {
      resultCode?: string;
      resultMsg?: string;
    };
    body?: {
      items?: {
        item?: QnetNationalQualificationItem | QnetNationalQualificationItem[];
      };
      totalCount?: number;
    };
  };
};

@Injectable()
export class QnetNationalQualificationClient {
  private readonly parser = new XMLParser({
    ignoreAttributes: false,
    trimValues: true,
  });

  constructor(private readonly config: ConfigService) {}

  async fetchList() {
    const serviceKey = this.config.get<string>('QNET_SERVICE_KEY');
    const endpoint = this.config.get<string>(
      'QNET_NATIONAL_QUALIFICATION_LIST_URL',
      'http://openapi.q-net.or.kr/api/service/rest/InquiryListNationalQualifcationSVC/getList',
    );

    if (!serviceKey) {
      throw new Error('QNET_SERVICE_KEY is missing in server/.env.');
    }

    const url = new URL(endpoint);
    url.searchParams.set('serviceKey', serviceKey);

    const response = await fetch(url);
    const xml = await response.text();

    if (!response.ok) {
      throw new Error(`Q-Net qualification list API failed: ${response.status} ${xml}`);
    }

    const parsed = this.parser.parse(xml) as QnetListResponse;
    const header = parsed.response?.header;

    const resultCode = header?.resultCode == null ? undefined : String(header.resultCode).padStart(2, '0');

    if (resultCode && resultCode !== '00') {
      throw new Error(`Q-Net qualification list API error: ${resultCode} ${header?.resultMsg ?? ''}`);
    }

    const item = parsed.response?.body?.items?.item;
    const items = Array.isArray(item) ? item : item ? [item] : [];

    return {
      totalCount: Number(parsed.response?.body?.totalCount ?? items.length),
      items: items.filter((row) => row.jmcd && row.jmfldnm),
    };
  }
}
