import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { XMLParser } from 'fast-xml-parser';

export type QnetExamEligibilityItem = {
  emqualCd: string;
  emqualDispNm: string;
  grdCd: string | number;
  grdNm: string;
  qualgbCd: string;
  qualgbNm: string;
  [key: string]: unknown;
};

type QnetExamEligibilityResponse = {
  response?: {
    header?: {
      resultCode?: string | number;
      resultMsg?: string;
    };
    body?: {
      items?: {
        item?: QnetExamEligibilityItem | QnetExamEligibilityItem[];
      };
      totalCount?: number;
    };
  };
};

@Injectable()
export class QnetExamEligibilityClient {
  private readonly parser = new XMLParser({
    ignoreAttributes: false,
    trimValues: true,
  });

  constructor(private readonly config: ConfigService) {}

  async fetchPage(pageNo: number, numOfRows: number) {
    let lastError: Error | undefined;

    for (let attempt = 1; attempt <= 3; attempt += 1) {
      try {
        return await this.fetchPageOnce(pageNo, numOfRows);
      } catch (error) {
        lastError = error instanceof Error ? error : new Error(String(error));

        if (!lastError.message.includes('API error: 99') || attempt === 3) {
          throw lastError;
        }

        await new Promise((resolve) => setTimeout(resolve, 700 * attempt));
      }
    }

    throw lastError ?? new Error('Q-Net exam eligibility API failed.');
  }

  private async fetchPageOnce(pageNo: number, numOfRows: number) {
    const serviceKey = this.config.get<string>('QNET_SERVICE_KEY');
    const endpoint = this.config.get<string>(
      'QNET_EXAM_ELIGIBILITY_URL',
      'http://openapi.q-net.or.kr/api/service/rest/InquiryExamQualItemSVC/getList',
    );

    if (!serviceKey) {
      throw new Error('QNET_SERVICE_KEY is missing in server/.env.');
    }

    const url = new URL(endpoint);
    url.searchParams.set('serviceKey', serviceKey);
    url.searchParams.set('pageNo', String(pageNo));
    url.searchParams.set('numOfRows', String(numOfRows));

    const response = await fetch(url);
    const xml = await response.text();

    if (!response.ok) {
      throw new Error(`Q-Net exam eligibility API failed: ${response.status} ${xml}`);
    }

    const parsed = this.parser.parse(xml) as QnetExamEligibilityResponse;
    const header = parsed.response?.header;
    const resultCode = header?.resultCode == null ? undefined : String(header.resultCode).padStart(2, '0');

    if (resultCode && resultCode !== '00') {
      throw new Error(`Q-Net exam eligibility API error: ${resultCode} ${header?.resultMsg ?? ''}`);
    }

    const item = parsed.response?.body?.items?.item;
    const items = Array.isArray(item) ? item : item ? [item] : [];

    return {
      totalCount: Number(parsed.response?.body?.totalCount ?? items.length),
      items: items.filter((row) => row.emqualCd && row.emqualDispNm),
    };
  }
}
