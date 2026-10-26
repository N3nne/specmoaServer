import { JobPostingEntity } from '../jobs/entities/job-posting.entity';
import { compareJob } from '../jobs/job-match';
import { JobStatus, jobStatus } from '../jobs/job.types';
import { DemoJobSource } from '../jobs/providers/demo-job.source';
import { SpecData, SpecType } from '../specs/spec-types';

export enum DemoProfile {
  BACKEND = 'backend',
  MOBILE = 'mobile',
  DATA = 'data',
}

export const DEMO_PROFILE_DETAILS: Record<
  DemoProfile,
  { profileLabel: string; profileSummary: string }
> = {
  backend: {
    profileLabel: '가상 백엔드 프로필',
    profileSummary: '학사 졸업 · 서버 프로젝트 · TOEIC 750점',
  },
  mobile: {
    profileLabel: '가상 모바일 프로필',
    profileSummary: '전문학사 졸업 · Flutter 앱 프로젝트',
  },
  data: {
    profileLabel: '가상 데이터 프로필',
    profileSummary: '학사 졸업 · Python·SQL 분석 프로젝트',
  },
};

type DemoSpec = { id: string; type: SpecType; data: SpecData };
export type EvidenceRecord = { id: string; fields: Record<string, string> };
export type DemoCandidate = EvidenceRecord & {
  companyName: string;
  metadata: {
    region: string;
    experienceLevel: string | null;
    employmentType: string;
  };
  comparison: ReturnType<typeof compareJob>;
};
export type RecommendationInput = {
  profileId: DemoProfile;
  specs: EvidenceRecord[];
  jobs: DemoCandidate[];
};

// These fixtures are authored here, never loaded from user records or request text.
const profiles: Record<DemoProfile, DemoSpec[]> = {
  backend: [
    {
      id: 'demo-backend-degree',
      type: SpecType.EDUCATION_RECORD,
      data: { degree: '학사', academicStatus: '졸업' },
    },
    {
      id: 'demo-backend-project',
      type: SpecType.PROJECT,
      data: {
        skills: ['TypeScript', 'NestJS', 'PostgreSQL'],
        description:
          '가상 팀 프로젝트에서 사용자 인증 API, 데이터베이스 설계, 서버 테스트를 담당했습니다.',
      },
    },
    {
      id: 'demo-backend-language',
      type: SpecType.LANGUAGE_SCORE,
      data: { exam: 'TOEIC', score: 750 },
    },
  ],
  mobile: [
    {
      id: 'demo-mobile-degree',
      type: SpecType.EDUCATION_RECORD,
      data: { degree: '전문학사', academicStatus: '졸업' },
    },
    {
      id: 'demo-mobile-project',
      type: SpecType.PROJECT,
      data: {
        skills: ['Flutter', 'Dart', 'Git'],
        description:
          '가상 팀 프로젝트에서 모바일 화면, 서버 통신, 접근성 개선과 앱 테스트를 담당했습니다.',
      },
    },
  ],
  data: [
    {
      id: 'demo-data-degree',
      type: SpecType.EDUCATION_RECORD,
      data: { degree: '학사', academicStatus: '졸업' },
    },
    {
      id: 'demo-data-project',
      type: SpecType.PROJECT,
      data: {
        skills: ['Python', 'SQL', '통계'],
        description:
          '가상 프로젝트에서 데이터를 정제하고 지표 및 대시보드를 설계했습니다.',
      },
    },
  ],
};

export async function demoRecommendationInput(
  profile: DemoProfile,
  now: Date,
): Promise<RecommendationInput> {
  const specs = profiles[profile];
  if (!specs) throw new Error('Unknown demo profile.');
  const source = new DemoJobSource();
  const postings = await source.load(now);
  return {
    profileId: profile,
    specs: specs.map((spec) => ({
      id: spec.id,
      fields: {
        type: spec.type,
        ...Object.fromEntries(
          Object.entries(spec.data).map(([key, value]) => [
            key,
            Array.isArray(value) ? value.join(', ') : String(value),
          ]),
        ),
      },
    })),
    jobs: postings
      .filter(
        (job, index) =>
          index % 4 === 0 && jobStatus(job, now) === JobStatus.OPEN,
      )
      .map((item) => ({
        id: item.externalId,
        companyName: item.companyName,
        metadata: {
          region: item.region,
          experienceLevel: item.experienceLevel,
          employmentType: item.employmentType,
        },
        fields: {
          title: item.title,
          description: item.description ?? '',
          requirements:
            item.requirements
              ?.map(
                (rule) =>
                  `${rule.required ? '필수' : '우대'}: ${rule.name}${rule.minimumScore === undefined ? '' : ` ${rule.minimumScore}점 이상`}`,
              )
              .join('\n') ?? '',
        },
        comparison: compareJob(
          Object.assign(new JobPostingEntity(), item),
          specs,
          now,
        ),
      })),
  };
}
