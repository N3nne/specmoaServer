import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { XMLParser } from 'fast-xml-parser';

export type QnetCertificationDetailItem = {
  jmfldnm: string;
  infogb: string;
  contents: string;
  obligfldcd?: string;
  obligfldnm?: string;
  mdobligfldcd?: string;
  mdobligfldnm?: string;
  [key: string]: unknown;
};

type QnetDetailResponse = {
  response?: {
    header?: {
      resultCode?: string | number;
      resultMsg?: string;
    };
    body?: {
      items?: {
        item?: QnetCertificationDetailItem | QnetCertificationDetailItem[];
      };
      totalCount?: number;
    };
  };
};

@Injectable()
export class QnetCertificationDetailClient {
  private readonly parser = new XMLParser({
    ignoreAttributes: false,
    trimValues: true,
  });

  constructor(private readonly config: ConfigService) {}

  async fetchByJmCd(jmCd: string) {
    let lastError: Error | undefined;

    for (let attempt = 1; attempt <= 3; attempt += 1) {
      try {
        return await this.fetchByJmCdOnce(jmCd);
      } catch (error) {
        lastError = error instanceof Error ? error : new Error(String(error));
        if (attempt >= 2) {
          throw lastError;
        }

        const retryable =
          lastError.message.includes('API error: 99') ||
          lastError.message.includes('timed out') ||
          lastError.name === 'AbortError';

        if (!retryable) {
          throw lastError;
        }

        await new Promise((resolve) => setTimeout(resolve, 800 * attempt));
      }
    }

    throw lastError ?? new Error('Q-Net certification detail API failed.');
  }

  private async fetchByJmCdOnce(jmCd: string) {
    const serviceKey = this.config.get<string>('QNET_SERVICE_KEY');
    const endpoint = this.config.get<string>(
      'QNET_CERTIFICATION_DETAIL_URL',
      'http://openapi.q-net.or.kr/api/service/rest/InquiryInformationTradeNTQSVC/getList',
    );

    if (!serviceKey) {
      throw new Error('QNET_SERVICE_KEY is missing in server/.env.');
    }

    const url = new URL(endpoint);
    url.searchParams.set('serviceKey', serviceKey);
    url.searchParams.set('jmCd', jmCd);

    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), 10_000);
    const response = await fetch(url, { signal: controller.signal }).finally(() =>
      clearTimeout(timeout),
    );
    const xml = await response.text();

    if (!response.ok) {
      throw new Error(`Q-Net certification detail API failed: ${response.status} ${xml}`);
    }

    const parsed = this.parser.parse(xml) as QnetDetailResponse;
    const header = parsed.response?.header;
    const resultCode = header?.resultCode == null ? undefined : String(header.resultCode).padStart(2, '0');

    if (resultCode && resultCode !== '00') {
      throw new Error(`Q-Net certification detail API error: ${resultCode} ${header?.resultMsg ?? ''}`);
    }

    const item = parsed.response?.body?.items?.item;
    const items = Array.isArray(item) ? item : item ? [item] : [];

    return {
      totalCount: Number(parsed.response?.body?.totalCount ?? items.length),
      items: items.filter((row) => row.infogb && row.contents),
    };
  }
}
