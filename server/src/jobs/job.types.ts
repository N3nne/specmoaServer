export const JOB_SOURCE = Symbol('JOB_SOURCE');
export const DEMO_NOTICE = '시연용 가상 공고입니다. 실제 기업의 채용이나 지원 접수와 관계없습니다.';

export enum EmploymentType { FULL_TIME = 'full_time', CONTRACT = 'contract', INTERN = 'intern' }
export enum EducationLevel { ANY = 'any', HIGH_SCHOOL = 'high_school', ASSOCIATE = 'associate', BACHELOR = 'bachelor', MASTER = 'master', DOCTOR = 'doctor' }
export enum ExperienceLevel { ANY = 'any', ENTRY = 'entry', EXPERIENCED = 'experienced' }
export enum JobStatus { OPEN = 'open', CLOSED = 'closed', UPCOMING = 'upcoming', ALL = 'all' }
export enum JobSort { LATEST = 'latest', DEADLINE = 'deadline' }

export type JobRequirement = {
  kind: 'skill' | 'certification' | 'language_score';
  name: string;
  minimumScore?: number;
  required: boolean;
};

// Provider-specific responses stop here. Unknown values remain null, not invented defaults.
export interface JobFeedItem {
  externalId: string;
  companyName: string;
  title: string;
  occupation: string;
  region: string;
  employmentType: EmploymentType;
  educationLevel: EducationLevel | null;
  experienceLevel: ExperienceLevel | null;
  minExperienceMonths: number | null;
  salaryText: string | null;
  keywords: string[];
  postedAt: Date;
  opensAt: Date;
  closesAt: Date | null;
  active: boolean;
  sourceUrl: string | null;
  description: string | null;
  requirements: JobRequirement[] | null;
}

export interface JobSource {
  readonly source: string;
  readonly synthetic: boolean;
  readonly notice: string;
  readonly datasetVersion: string | null;
  load(asOf: Date): Promise<JobFeedItem[]>;
}

export function jobStatus(job: Pick<JobFeedItem, 'active' | 'opensAt' | 'closesAt'>, now: Date): Exclude<JobStatus, JobStatus.ALL> {
  if (!job.active || job.closesAt && job.closesAt <= now) return JobStatus.CLOSED;
  if (job.opensAt > now) return JobStatus.UPCOMING;
  return JobStatus.OPEN;
}
