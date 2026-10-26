import { DEMO_NOTICE, EducationLevel, EmploymentType, ExperienceLevel, JobFeedItem, JobRequirement, JobSource } from '../job.types';
import { JobOccupation } from '../job-occupations';

type Role = {
  code: JobOccupation; name: string; company: string; task: string; skills: string[];
  certification: string; education: EducationLevel; salary: string;
};

// Wholly fictional scenarios, not copied postings or claims about real employers.
const roles: Role[] = [
  { code: 'backend', name: '백엔드 개발', company: '스펙모아 가상기업 01', task: '사용자 서비스 API와 데이터베이스를 개발합니다.', skills: ['TypeScript', 'NestJS', 'PostgreSQL'], certification: '정보처리기사', education: EducationLevel.BACHELOR, salary: '연 3,600~4,600만원' },
  { code: 'frontend', name: '프론트엔드 개발', company: '스펙모아 가상기업 02', task: '웹 화면과 접근성, 사용자 상호작용을 구현합니다.', skills: ['JavaScript', 'React', 'HTML'], certification: '정보처리기사', education: EducationLevel.ANY, salary: '연 3,400~4,400만원' },
  { code: 'mobile', name: '모바일 앱 개발', company: '스펙모아 가상기업 03', task: '모바일 화면과 서버 통신, 앱 테스트를 담당합니다.', skills: ['Flutter', 'Dart', 'Git'], certification: '정보처리산업기사', education: EducationLevel.ASSOCIATE, salary: '연 3,400~4,500만원' },
  { code: 'data', name: '데이터 분석', company: '스펙모아 가상기업 04', task: '데이터를 정제하고 지표와 대시보드를 설계합니다.', skills: ['Python', 'SQL', '통계'], certification: 'SQLD', education: EducationLevel.BACHELOR, salary: '연 3,500~4,700만원' },
  { code: 'design', name: 'UX/UI 디자인', company: '스펙모아 가상기업 05', task: '사용자 흐름과 디자인 시스템을 설계합니다.', skills: ['Figma', '프로토타이핑', '사용자 조사'], certification: '컴퓨터그래픽스운용기능사', education: EducationLevel.ANY, salary: '연 3,200~4,200만원' },
  { code: 'marketing', name: '디지털 마케팅', company: '스펙모아 가상기업 06', task: '콘텐츠와 캠페인의 성과를 측정하고 개선합니다.', skills: ['GA4', '콘텐츠 기획', 'Excel'], certification: '검색광고마케터', education: EducationLevel.ANY, salary: '연 3,000~4,000만원' },
  { code: 'accounting', name: '회계·재무', company: '스펙모아 가상기업 07', task: '회계 전표와 월별 정산 자료를 관리합니다.', skills: ['Excel', '재무회계', 'ERP'], certification: '전산회계1급', education: EducationLevel.ASSOCIATE, salary: '연 3,100~4,100만원' },
  { code: 'electrical', name: '전기설비 관리', company: '스펙모아 가상기업 08', task: '전기설비 점검과 유지보수 계획을 수립합니다.', skills: ['전기도면', '설비점검', '안전관리'], certification: '전기기사', education: EducationLevel.ASSOCIATE, salary: '연 3,400~4,600만원' },
  { code: 'safety', name: '산업안전 관리', company: '스펙모아 가상기업 09', task: '위험성 평가와 현장 안전교육을 지원합니다.', skills: ['위험성 평가', '안전교육', '문서작성'], certification: '산업안전기사', education: EducationLevel.BACHELOR, salary: '연 3,400~4,600만원' },
  { code: 'mechanical', name: '기계설계', company: '스펙모아 가상기업 10', task: '기계 부품 도면과 시제품 검토를 담당합니다.', skills: ['AutoCAD', 'SolidWorks', '기계도면'], certification: '일반기계기사', education: EducationLevel.BACHELOR, salary: '연 3,500~4,800만원' },
];

export class DemoJobSource implements JobSource {
  readonly source = 'demo';
  readonly synthetic = true;
  readonly notice = DEMO_NOTICE;
  readonly datasetVersion = 'specmoa-demo-v1';

  async load(asOf: Date): Promise<JobFeedItem[]> {
    if (!Number.isFinite(asOf.getTime())) throw new Error('Invalid demo reference date.');
    // Use a KST calendar date so identical seed dates produce identical fixtures on every host.
    const day = new Date(asOf.getTime() + 9 * 60 * 60 * 1000).toISOString().slice(0, 10);
    const at = (offset: number) => new Date(Date.parse(`${day}T00:00:00+09:00`) + offset * 86_400_000);
    const regions = ['서울', '경기', '부산', '대전', '대구', '광주', '인천', '울산'];
    return roles.flatMap((role, roleIndex) => Array.from({ length: 4 }, (_, variant) => {
      const index = roleIndex * 4 + variant;
      const intern = variant === 1;
      const experienced = variant === 2;
      const closed = roleIndex >= 6 && variant === 3;
      const upcoming = roleIndex === 9 && variant === 0;
      const requirements: JobRequirement[] | null = variant === 3 ? null : [
        ...role.skills.map((name, i) => ({ kind: 'skill' as const, name, required: i === 0 })),
        { kind: 'certification', name: role.certification, required: roleIndex === 7 || roleIndex === 8 },
        ...(roleIndex % 3 === 0 ? [{ kind: 'language_score' as const, name: 'TOEIC', minimumScore: experienced ? 800 : 700, required: false }] : []),
      ];
      return {
        externalId: `${this.datasetVersion}-${String(index + 1).padStart(3, '0')}`,
        companyName: role.company,
        title: `[가상 공고] ${role.name} ${intern ? '체험형 인턴' : experienced ? '경력' : variant === 3 ? '계약직' : '신입'} 모집`,
        occupation: role.code, region: regions[(roleIndex + variant * 2) % regions.length],
        employmentType: intern ? EmploymentType.INTERN : variant === 3 ? EmploymentType.CONTRACT : EmploymentType.FULL_TIME,
        educationLevel: role.education,
        experienceLevel: experienced ? ExperienceLevel.EXPERIENCED : variant === 3 ? ExperienceLevel.ANY : ExperienceLevel.ENTRY,
        minExperienceMonths: experienced ? 24 : null,
        salaryText: intern ? '월 230만원 (가상 조건)' : role.salary,
        keywords: [role.name, ...role.skills, role.certification],
        postedAt: at(-((index % 12) + 1)), opensAt: at(upcoming ? 3 : -((index % 12) + 1)),
        closesAt: closed ? at(-1) : variant === 2 ? null : at((index % 20) + 7), active: !closed,
        sourceUrl: null, description: variant === 3 ? null : `${DEMO_NOTICE}\n\n담당 업무\n${role.task}\n\n필수 및 우대 조건\n${requirements!.map(item => `${item.required ? '필수' : '우대'}: ${item.name}${item.minimumScore ? ` ${item.minimumScore}점 이상` : ''}`).join('\n')}`,
        requirements,
      };
    }));
  }
}
