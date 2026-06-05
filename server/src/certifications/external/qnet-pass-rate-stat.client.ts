import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { XMLParser } from 'fast-xml-parser';

export type QnetPassRateStatItem = {
  emqualDispNm: string;
  grdNm: string;
  implSeq: string | number;
  implYy: string | number;
  pilPassCnt?: string | number;
  recptCnt?: string | number;
  silPassCnt?: string | number;
  [key: string]: unknown;
};

type QnetPassRateStatResponse = {
  response?: {
    header?: {
      resultCode?: string | number;
      resultMsg?: string;
    };
    body?: {
      items?: {
        item?: QnetPassRateStatItem | QnetPassRateStatItem[];
      };
      totalCount?: number;
    };
  };
};

@Injectable()
export class QnetPassRateStatClient {
  private readonly parser = new XMLParser({
    ignoreAttributes: false,
    trimValues: true,
  });

  constructor(private readonly config: ConfigService) {}

  async fetchPage(baseYear: number, gradeCode: string, pageNo: number, numOfRows: number) {
    let lastError: Error | undefined;

    for (let attempt = 1; attempt <= 3; attempt += 1) {
      try {
        return await this.fetchPageOnce(baseYear, gradeCode, pageNo, numOfRows);
      } catch (error) {
        lastError = error instanceof Error ? error : new Error(String(error));

        if (!lastError.message.includes('API error: 99') || attempt === 3) {
          throw lastError;
        }

        await new Promise((resolve) => setTimeout(resolve, 700 * attempt));
      }
    }

    throw lastError ?? new Error('Q-Net pass rate stat API failed.');
  }

  private async fetchPageOnce(
    baseYear: number,
    gradeCode: string,
    pageNo: number,
    numOfRows: number,
  ) {
    const serviceKey = this.config.get<string>('QNET_SERVICE_KEY');
    const endpoint = this.config.get<string>(
      'QNET_PASS_RATE_STAT_URL',
      'http://openapi.q-net.or.kr/api/service/rest/InquiryEmqualPassSVC/getList',
    );

    if (!serviceKey) {
      throw new Error('QNET_SERVICE_KEY is missing in server/.env.');
    }

    const url = new URL(endpoint);
    url.searchParams.set('serviceKey', serviceKey);
    url.searchParams.set('baseYY', String(baseYear));
    url.searchParams.set('grdCd', gradeCode);
    url.searchParams.set('pageNo', String(pageNo));
    url.searchParams.set('numOfRows', String(numOfRows));

    const response = await fetch(url);
    const xml = await response.text();

    if (!response.ok) {
      throw new Error(`Q-Net pass rate stat API failed: ${response.status} ${xml}`);
    }

    const parsed = this.parser.parse(xml) as QnetPassRateStatResponse;
    const header = parsed.response?.header;
    const resultCode = header?.resultCode == null ? undefined : String(header.resultCode).padStart(2, '0');

    if (resultCode && resultCode !== '00') {
      throw new Error(`Q-Net pass rate stat API error: ${resultCode} ${header?.resultMsg ?? ''}`);
    }

    const item = parsed.response?.body?.items?.item;
    const items = Array.isArray(item) ? item : item ? [item] : [];

    return {
      totalCount: Number(parsed.response?.body?.totalCount ?? items.length),
      items: items.filter((row) => row.emqualDispNm && row.grdNm && row.implSeq),
    };
  }
}
