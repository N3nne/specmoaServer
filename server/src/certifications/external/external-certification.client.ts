import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

import { ExternalCertification } from './external-certification.types';

@Injectable()
export class ExternalCertificationClient {
  constructor(private readonly config: ConfigService) {}

  async fetchCertifications(): Promise<ExternalCertification[]> {
    const apiUrl = this.config.get<string>('EXTERNAL_CERT_API_URL');

    if (!apiUrl) {
      return this.localSeed();
    }

    const response = await fetch(apiUrl, {
      headers: this.buildHeaders(),
    });

    if (!response.ok) {
      throw new Error(`External certification API failed: ${response.status}`);
    }

    const data = (await response.json()) as ExternalCertification[];
    return data;
  }

  private buildHeaders(): Record<string, string> {
    const apiKey = this.config.get<string>('EXTERNAL_CERT_API_KEY');
    return apiKey ? { Authorization: `Bearer ${apiKey}` } : {};
  }

  private localSeed(): ExternalCertification[] {
    return [
      {
        externalSource: 'local-seed',
        externalId: 'engineer-information-processing',
        name: '정보처리기사',
        englishName: 'Engineer Information Processing',
        category: 'IT',
        organization: '한국산업인력공단',
        description: '정보 시스템 개발과 운영 역량을 검증하는 국가기술자격입니다.',
        schedules: [
          {
            type: 'registration',
            title: '2026년 1회 필기 접수',
            startsOn: '2026-01-12',
            endsOn: '2026-01-15',
          },
          {
            type: 'written',
            title: '2026년 1회 필기 시험',
            startsOn: '2026-02-08',
          },
        ],
      },
      {
        externalSource: 'local-seed',
        externalId: 'sqld',
        name: 'SQLD',
        englishName: 'SQL Developer',
        category: 'Data',
        organization: '한국데이터산업진흥원',
        description: 'SQL 활용과 데이터 모델링 기초 역량을 검증하는 민간 자격입니다.',
      },
    ];
  }
}
