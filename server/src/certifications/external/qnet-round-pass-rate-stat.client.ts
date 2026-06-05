import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { XMLParser } from 'fast-xml-parser';

export type QnetRoundPassRateStatItem = {
  examPassCnt?: string | number;
  examTypCcd: string;
  grdNm: string;
  implSeq: string | number;
  implYy: string | number;
  jmCd: string | number;
  jmFldNm: string;
  passRate?: string | number;
  recptNoCnt?: string | number;
  [key: string]: unknown;
};

type QnetRoundPassRateStatResponse = {
  response?: {
    header?: {
      resultCode?: string | number;
      resultMsg?: string;
    };
    body?: {
      items?: {
        item?: QnetRoundPassRateStatItem | QnetRoundPassRateStatItem[];
      };
      totalCount?: number;
    };
  };
};

@Injectable()
export class QnetRoundPassRateStatClient {
  private readonly parser = new XMLParser({
    ignoreAttributes: false,
    trimValues: true,
  });

  constructor(private readonly config: ConfigService) {}

  async fetchPage(baseYear: number, gradeCode: string, pageNo: number, numOfRows: number) {
    let lastError: Error | undefined;

    for (let attempt = 1; attempt <= 6; attempt += 1) {
      try {
        return await this.fetchPageOnce(baseYear, gradeCode, pageNo, numOfRows);
      } catch (error) {
        lastError = error instanceof Error ? error : new Error(String(error));

        if (!lastError.message.includes('API error: 99') || attempt === 6) {
          throw lastError;
        }

        await new Promise((resolve) => setTimeout(resolve, 1000 * attempt));
      }
    }

    throw lastError ?? new Error('Q-Net round pass rate stat API failed.');
  }

  private async fetchPageOnce(
    baseYear: number,
    gradeCode: string,
    pageNo: number,
    numOfRows: number,
  ) {
    const serviceKey = this.config.get<string>('QNET_SERVICE_KEY');
    const endpoint = this.config.get<string>(
      'QNET_ROUND_PASS_RATE_STAT_URL',
      'http://openapi.q-net.or.kr/api/service/rest/InquiryQualPassRateSVC/getList',
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
      throw new Error(`Q-Net round pass rate stat API failed: ${response.status} ${xml}`);
    }

    const parsed = this.parser.parse(xml) as QnetRoundPassRateStatResponse;
    const header = parsed.response?.header;
    const resultCode =
      header?.resultCode == null ? undefined : String(header.resultCode).padStart(2, '0');

    if (resultCode && resultCode !== '00') {
      throw new Error(`Q-Net round pass rate stat API error: ${resultCode} ${header?.resultMsg ?? ''}`);
    }

    const item = parsed.response?.body?.items?.item;
    const items = Array.isArray(item) ? item : item ? [item] : [];

    return {
      totalCount: Number(parsed.response?.body?.totalCount ?? items.length),
      items: items.filter(
        (row) => row.jmCd && row.jmFldNm && row.implSeq != null && row.examTypCcd,
      ),
    };
  }
}
