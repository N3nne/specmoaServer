import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { XMLParser } from 'fast-xml-parser';

export type QnetExamScheduleItem = {
  implplannm: string;
  jmfldnm: string;
  docregstartdt?: number | string;
  docregenddt?: number | string;
  docexamstartdt?: number | string;
  docexamenddt?: number | string;
  docpassdt?: number | string;
  docsubmitstartdt?: number | string;
  docsubmitenddt?: number | string;
  pracregstartdt?: number | string;
  pracregenddt?: number | string;
  pracexamstartdt?: number | string;
  pracexamenddt?: number | string;
  pracpassstartdt?: number | string;
  pracpassenddt?: number | string;
  [key: string]: unknown;
};

type QnetExamScheduleResponse = {
  response?: {
    header?: {
      resultCode?: string | number;
      resultMsg?: string;
    };
    body?: {
      items?: {
        item?: QnetExamScheduleItem | QnetExamScheduleItem[];
      };
      totalCount?: number;
    };
  };
};

@Injectable()
export class QnetExamScheduleClient {
  private readonly parser = new XMLParser({
    ignoreAttributes: false,
    trimValues: true,
  });

  constructor(private readonly config: ConfigService) {}

  async fetchByJmCd(jmCd: string) {
    const serviceKey = this.config.get<string>('QNET_SERVICE_KEY');
    const endpoint = this.config.get<string>(
      'QNET_EXAM_SCHEDULE_URL',
      'http://openapi.q-net.or.kr/api/service/rest/InquiryTestInformationNTQSVC/getJMList',
    );

    if (!serviceKey) {
      throw new Error('QNET_SERVICE_KEY is missing in server/.env.');
    }

    const url = new URL(endpoint);
    url.searchParams.set('serviceKey', serviceKey);
    url.searchParams.set('jmCd', jmCd);

    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), 15_000);
    const response = await fetch(url, { signal: controller.signal }).finally(() =>
      clearTimeout(timeout),
    );
    const xml = await response.text();

    if (!response.ok) {
      throw new Error(`Q-Net exam schedule API failed: ${response.status} ${xml}`);
    }

    const parsed = this.parser.parse(xml) as QnetExamScheduleResponse;
    const header = parsed.response?.header;
    const resultCode = header?.resultCode == null ? undefined : String(header.resultCode).padStart(2, '0');

    if (resultCode && resultCode !== '00') {
      throw new Error(`Q-Net exam schedule API error: ${resultCode} ${header?.resultMsg ?? ''}`);
    }

    const item = parsed.response?.body?.items?.item;
    const items = Array.isArray(item) ? item : item ? [item] : [];

    return {
      totalCount: Number(parsed.response?.body?.totalCount ?? items.length),
      items: items.filter((row) => row.implplannm),
    };
  }
}
