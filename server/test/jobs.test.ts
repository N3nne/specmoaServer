import 'reflect-metadata';
import * as assert from 'node:assert/strict';
import { test } from 'node:test';
import { plainToInstance } from 'class-transformer';
import { validateSync } from 'class-validator';
import { Repository } from 'typeorm';
import { SpecType } from '../src/specs/spec-types';
import { JobPostingEntity } from '../src/jobs/entities/job-posting.entity';
import { ListJobsDto } from '../src/jobs/dto/list-jobs.dto';
import { compareJob } from '../src/jobs/job-match';
import { importJobs } from '../src/jobs/job-import';
import { EducationLevel, EmploymentType, ExperienceLevel, JobFeedItem, JobSort, JobStatus, jobStatus } from '../src/jobs/job.types';
import { DemoJobSource } from '../src/jobs/providers/demo-job.source';
import { configuredJobSource } from '../src/jobs/providers/job-source.factory';

const now = new Date('2026-10-22T00:00:00+09:00');
const source = new DemoJobSource();
const spec = (id: string, type: SpecType, data: Record<string, string | number | boolean | string[]>) => ({ id, type, data });
const asJob = (item: JobFeedItem) => Object.assign(new JobPostingEntity(), item);
const comparisonJob = (overrides: Partial<JobPostingEntity> = {}): JobPostingEntity => Object.assign(new JobPostingEntity(), {
  educationLevel: EducationLevel.BACHELOR, experienceLevel: ExperienceLevel.EXPERIENCED,
  minExperienceMonths: 24, requirements: [],
}, overrides);

test('demo feed has 40 deterministic fictional postings across 10 roles, 8 regions and 3 employment types', async () => {
  const items = await source.load(now);
  assert.equal(items.length, 40);
  assert.deepEqual(await source.load(now), items);
  assert.equal(new Set(items.map(item => item.externalId)).size, 40);
  assert.equal(new Set(items.map(item => item.occupation)).size, 10);
  assert.equal(new Set(items.map(item => item.region)).size, 8);
  assert.equal(new Set(items.map(item => item.employmentType)).size, 3);
  for (const item of items) {
    assert.ok(item.companyName.startsWith('스펙모아 가상기업'));
    assert.ok(item.title.startsWith('[가상 공고]'));
    assert.equal(item.sourceUrl, null);
  }
  assert.equal(items.filter(item => jobStatus(item, now) === JobStatus.OPEN).length, 35);
  assert.equal(items.filter(item => jobStatus(item, now) === JobStatus.CLOSED).length, 4);
  assert.equal(items.filter(item => jobStatus(item, now) === JobStatus.UPCOMING).length, 1);
  assert.equal(items.filter(item => item.closesAt === null).length, 10);
  assert.equal(items.filter(item => item.requirements === null && item.description === null).length, 10);
});

test('production does not silently enable demo; unimplemented providers fail instead of falling back', () => {
  assert.equal(configuredJobSource({ NODE_ENV: 'production' }).source, 'disabled');
  assert.equal(configuredJobSource({ NODE_ENV: 'development' }).source, 'demo');
  assert.equal(configuredJobSource({ NODE_ENV: 'production', JOBS_SOURCE: 'demo' }).synthetic, true);
  assert.throws(() => configuredJobSource({ JOBS_SOURCE: 'saramin' }), /not implemented/);
});

test('query defaults, enums and pagination reject malformed or ownership-injecting query values', () => {
  assert.equal(plainToInstance(ListJobsDto, {}).status, JobStatus.OPEN);
  assert.equal(plainToInstance(ListJobsDto, {}).limit, 20);
  const good = plainToInstance(ListJobsDto, { q: ' NestJS ', limit: '5', offset: '0', sort: 'deadline', employmentType: 'intern' });
  assert.deepEqual(validateSync(good, { whitelist: true, forbidNonWhitelisted: true }), []);
  assert.equal(good.q, 'NestJS');
  assert.equal(good.sort, JobSort.DEADLINE);
  assert.equal(good.employmentType, EmploymentType.INTERN);
  for (const query of [{ limit: 0 }, { limit: 101 }, { offset: -1 }, { limit: 'abc' }, { source: 'saramin' }, { userId: 'other' }, { region: ['서울'] }, { status: 'bad' }]) {
    assert.ok(validateSync(plainToInstance(ListJobsDto, query), { whitelist: true, forbidNonWhitelisted: true }).length > 0);
  }
});

test('job status handles exact opening and closing boundaries, null deadlines and inactive jobs', async () => {
  const job = (await source.load(now))[0];
  assert.equal(jobStatus({ ...job, opensAt: now, closesAt: new Date(now.getTime() + 1) }, now), 'open');
  assert.equal(jobStatus({ ...job, closesAt: now }, now), 'closed');
  assert.equal(jobStatus({ ...job, opensAt: new Date(now.getTime() + 1), closesAt: null }, now), 'upcoming');
  assert.equal(jobStatus({ ...job, active: false, closesAt: null }, now), 'closed');
});

test('import validates the entire batch before writing and strips provider-owned identity fields', async () => {
  let saved: Record<string, unknown>[] = [];
  let transactions = 0;
  const repository = { manager: { transaction: async (run: (manager: unknown) => Promise<void>) => {
    transactions++;
    await run({ getRepository: () => ({ upsert: async (items: Record<string, unknown>[]) => { saved = items; } }) });
  } } } as unknown as Repository<JobPostingEntity>;
  const original = (await source.load(now))[0];
  await importJobs(repository, { ...source, load: async () => [{ ...original, id: 'do-not-use', source: 'forged', synthetic: false } as JobFeedItem] }, now);
  assert.equal(saved.length, 1);
  assert.equal(saved[0].id, undefined);
  assert.equal(saved[0].source, 'demo');
  assert.equal(saved[0].synthetic, true);
  for (const invalid of [
    { ...original, title: '' }, { ...original, sourceUrl: 'https://example.com/apply' },
    { ...original, postedAt: new Date('invalid') }, { ...original, employmentType: 'invalid' },
    { ...original, requirements: undefined }, { ...original, educationLevel: undefined },
    { ...original, closesAt: new Date('2000-01-01') },
    { ...original, requirements: [{ kind: 'language_score', name: 'TOEIC', required: true, minimumScore: -1 }] },
  ]) {
    await assert.rejects(() => importJobs(repository, { ...source, load: async () => [original, invalid as JobFeedItem] }, now));
  }
  await assert.rejects(() => importJobs(repository, { ...source, load: async () => [original, original] }, now), /Duplicate/);
  assert.equal(transactions, 1);
});

test('missing specs stay unknown, not failed; matching is not a probability or official certification', async () => {
  const job = asJob((await source.load(now))[0]);
  const result = compareJob(job, [], now);
  assert.equal(result.required.not_confirmed, 0);
  assert.equal(result.preferred.not_confirmed, 0);
  assert.equal(result.checks.every(check => check.status === 'unknown'), true);
  assert.ok(result.notice.includes('합격 확률'));
  assert.equal('score' in result, false);
});

test('completed degrees satisfy minimum education; enrollment and missing status remain unknown', async () => {
  const job = asJob((await source.load(now))[0]);
  for (const degree of ['학사', '석사', '박사']) {
    const result = compareJob(job, [spec('education', SpecType.EDUCATION_RECORD, { degree, academicStatus: '졸업' })], now);
    assert.equal(result.checks[0].status, 'confirmed');
  }
  assert.equal(compareJob(job, [spec('e', SpecType.EDUCATION_RECORD, { degree: '학사', academicStatus: '졸업예정' })], now).checks[0].status, 'unknown');
  assert.equal(compareJob(job, [spec('e', SpecType.EDUCATION_RECORD, { degree: '전문학사', academicStatus: '졸업' })], now).checks[0].status, 'not_confirmed');
  job.educationLevel = EducationLevel.ANY;
  assert.equal(compareJob(job, [], now).checks[0].status, 'not_required');
});

test('skill matching is exact after case/space normalization; unrelated substrings do not match', async () => {
  const job = asJob((await source.load(now))[0]);
  job.requirements = [{ kind: 'skill', name: 'Java', required: true }];
  assert.equal(compareJob(job, [spec('p', SpecType.PROJECT, { skills: ['JavaScript'] })], now).checks[2].status, 'unknown');
  assert.deepEqual(compareJob(job, [spec('p', SpecType.PROJECT, { skills: [' JAVA '] })], now).checks[2].evidenceSpecIds, ['p']);
});

test('certificate validity is not invented, and language comparisons explicitly exclude validity', async () => {
  const job = asJob((await source.load(now))[0]);
  job.requirements = [{ kind: 'certification', name: '정보처리기사', required: true }, { kind: 'language_score', name: 'TOEIC', minimumScore: 700, required: false }];
  const cert = { name: '정보처리기사', acquiredOn: '2025-01-01' };
  assert.equal(compareJob(job, [spec('c', SpecType.CERTIFICATION, cert)], now).checks[2].status, 'unknown');
  assert.equal(compareJob(job, [spec('c', SpecType.CERTIFICATION, { ...cert, expiresOn: '2026-10-21' })], now).checks[2].status, 'unknown');
  assert.equal(compareJob(job, [spec('c', SpecType.CERTIFICATION, { ...cert, lifetime: true })], now).checks[2].status, 'confirmed');
  const result = compareJob(job, [spec('l', SpecType.LANGUAGE_SCORE, { exam: 'TOEIC', score: 750 })], now);
  assert.equal(result.checks[3].status, 'confirmed');
  assert.ok(result.checks[3].condition.includes('유효기간 미판정'));
  assert.equal(compareJob(job, [spec('l', SpecType.LANGUAGE_SCORE, { exam: 'TOEIC', score: 650 })], now).checks[3].status, 'not_confirmed');
});

test('experience does not double-count overlapping months or infer zero from incomplete history', async () => {
  const job = asJob((await source.load(now))[2]);
  const work = (id: string, start: string, end: string) => spec(id, SpecType.WORK_EXPERIENCE, { employmentType: '정규직', startedMonth: start, endedMonth: end });
  assert.equal(compareJob(job, [work('a', '2025-01', '2026-01'), work('b', '2025-06', '2026-01')], now).checks[1].status, 'unknown');
  assert.equal(compareJob(job, [work('a', '2024-01', '2026-01')], now).checks[1].status, 'unknown');
  assert.equal(compareJob(job, [work('a', '2024-01', '2026-02')], now).checks[1].status, 'confirmed');
  assert.equal(compareJob(job, [spec('i', SpecType.WORK_EXPERIENCE, { employmentType: '인턴', startedMonth: '2020-01', ongoing: true })], now).checks[1].status, 'unknown');
  assert.equal(compareJob(job, [], now).checks[1].status, 'unknown');
  job.requirements = null;
  assert.equal(compareJob(job, [], now).detailedRequirementsAvailable, false);
  assert.equal(compareJob(job, [], now).checks.length, 2);
});

test('rules-v2 returns reasons, a reproducible comparison time and separate required/preferred totals', () => {
  const job = comparisonJob({ educationLevel: EducationLevel.ANY, requirements: [
    { kind: 'certification', name: '정보처리기사', required: true },
    { kind: 'language_score', name: 'TOEIC', minimumScore: 700, required: false },
  ] });
  const result = compareJob(job, [
    spec('cert', SpecType.CERTIFICATION, { name: '정보처리기사', acquiredOn: '2026-01-01', lifetime: true }),
    spec('score', SpecType.LANGUAGE_SCORE, { exam: 'TOEIC', score: 650 }),
  ], now);
  assert.equal(result.method, 'rules-v2');
  assert.equal(result.comparedAt, now.toISOString());
  assert.deepEqual(result.required, { confirmed: 1, not_confirmed: 0, unknown: 1, not_required: 1 });
  assert.deepEqual(result.preferred, { confirmed: 0, not_confirmed: 1, unknown: 0, not_required: 0 });
  for (const check of result.checks) {
    assert.ok(check.reason.length > 0);
    assert.ok(check.reasonCode.length > 0);
  }
  assert.equal('probability' in result, false);
  assert.equal('score' in result, false);
});

test('empty prototype records never become failed conditions', () => {
  const job = comparisonJob({ requirements: [
    { kind: 'certification', name: '정보처리기사', required: true },
    { kind: 'language_score', name: 'TOEIC', minimumScore: 700, required: true },
    { kind: 'skill', name: 'Java', required: false },
  ] });
  const emptySpecs = Object.values(SpecType).map(type => spec(type, type, {}));
  const result = compareJob(job, emptySpecs, now);
  assert.equal(result.checks.every(check => check.status === 'unknown'), true);
  assert.equal(result.required.not_confirmed + result.preferred.not_confirmed, 0);
  assert.equal(result.checks.every(check => check.evidenceSpecIds.length === 0), true);
});

test('lower degrees retain their evidence and an incomplete higher degree prevents a negative inference', () => {
  const job = comparisonJob();
  const lower = spec('associate', SpecType.EDUCATION_RECORD, { degree: '전문학사', academicStatus: '졸업' });
  const result = compareJob(job, [lower], now).checks[0];
  assert.equal(result.status, 'not_confirmed');
  assert.equal(result.reasonCode, 'below_minimum');
  assert.deepEqual(result.evidenceSpecIds, ['associate']);
  const pending = spec('bachelor', SpecType.EDUCATION_RECORD, { degree: '학사', academicStatus: '졸업예정' });
  assert.equal(compareJob(job, [lower, pending], now).checks[0].status, 'unknown');
  const graduated = spec('master', SpecType.EDUCATION_RECORD, { degree: '석사', academicStatus: '졸업' });
  assert.deepEqual(compareJob(job, [lower, pending, graduated], now).checks[0].evidenceSpecIds, ['master']);
});

test('unrecognized or incomplete degree values are unknown, not below-minimum evidence', () => {
  for (const degree of ['알 수 없는 학위', 'constructor', 'toString', '', ['학사'], 3]) {
    const result = compareJob(comparisonJob(), [
      spec('legacy', SpecType.EDUCATION_RECORD, { degree, academicStatus: '졸업' }),
    ], now).checks[0];
    assert.equal(result.status, 'unknown');
    assert.equal(result.reasonCode, 'evidence_incomplete');
  }
  assert.equal(compareJob(comparisonJob({ educationLevel: null }), [], now).checks[0].reasonCode, 'condition_missing');
});

test('certificate matching rejects partial names and invalid or future calendar dates', () => {
  const job = comparisonJob({ requirements: [{ kind: 'certification', name: '정보처리기사', required: true }] });
  const certification = (data: Record<string, string | boolean>) => spec('cert', SpecType.CERTIFICATION, { name: '정보처리기사', ...data });
  for (const acquiredOn of ['2026', '2026-02-30', '2026-10-23']) {
    assert.equal(compareJob(job, [certification({ acquiredOn, lifetime: true })], now).checks[2].status, 'unknown');
  }
  for (const expiresOn of ['2026-02-30', '2025-12-31']) {
    assert.equal(compareJob(job, [certification({ acquiredOn: '2026-01-01', expiresOn })], now).checks[2].status, 'unknown');
  }
  assert.equal(compareJob(job, [certification({ acquiredOn: '2026-01-01' })], now).checks[2].reasonCode, 'certificate_validity_unconfirmed');
  assert.equal(compareJob(job, [spec('other', SpecType.CERTIFICATION, {
    name: '정보처리산업기사', acquiredOn: '2026-01-01', lifetime: true,
  })], now).checks[2].reasonCode, 'evidence_missing');
  assert.equal(compareJob(job, [spec('normalized', SpecType.CERTIFICATION, {
    name: ' 정보처리 기사 ', acquiredOn: '2026-01-01', expiresOn: '2026-12-31',
  })], now).checks[2].status, 'confirmed');
});

test('certificate expiration uses the Korean date including the final valid day', () => {
  const job = comparisonJob({ requirements: [{ kind: 'certification', name: '정보처리기사', required: false }] });
  const cert = spec('cert', SpecType.CERTIFICATION, { name: '정보처리기사', acquiredOn: '2026-10-22', expiresOn: '2026-10-22' });
  const before = compareJob(job, [cert], new Date('2026-10-22T14:59:59Z')).checks[2];
  const after = compareJob(job, [cert], new Date('2026-10-22T15:00:00Z')).checks[2];
  assert.equal(before.status, 'confirmed');
  assert.equal(after.status, 'unknown');
  assert.equal(after.reasonCode, 'certificate_validity_unconfirmed');
  assert.deepEqual(after.evidenceSpecIds, ['cert']);
});

test('language compares only the same exam and keeps below-minimum evidence', () => {
  const job = comparisonJob({ requirements: [{ kind: 'language_score', name: 'TOEIC', minimumScore: 700, required: true }] });
  const low = spec('low', SpecType.LANGUAGE_SCORE, { exam: 'TOEIC', score: 650 });
  const unrelated = spec('speaking', SpecType.LANGUAGE_SCORE, { exam: '토익스피킹', score: 900 });
  const result = compareJob(job, [low, unrelated], now).checks[2];
  assert.equal(result.status, 'not_confirmed');
  assert.equal(result.reasonCode, 'below_minimum');
  assert.deepEqual(result.evidenceSpecIds, ['low']);
  const passed = spec('passed', SpecType.LANGUAGE_SCORE, { exam: ' ＴＯＥＩＣ ', score: 700 });
  assert.deepEqual(compareJob(job, [low, unrelated, passed], now).checks[2].evidenceSpecIds, ['passed']);
  assert.equal(compareJob(job, [spec('zero', SpecType.LANGUAGE_SCORE, { exam: 'TOEIC', score: 0 })], now).checks[2].status, 'not_confirmed');
});

test('invalid, grade-only and future language records cannot prove eligibility or cause failure', () => {
  const job = comparisonJob({ requirements: [{ kind: 'language_score', name: 'TOEIC', minimumScore: 700, required: true }] });
  const invalidRecords: Record<string, string | number>[] = [
    { score: -1 }, { score: NaN }, { score: Infinity }, { score: 991 }, { score: '900' },
    { grade: 'IH' }, { score: 900, testedOn: '2026-10-23' }, { score: 900, testedOn: '2026-02-30' },
  ];
  for (const data of invalidRecords) {
    const incomplete = spec('incomplete', SpecType.LANGUAGE_SCORE, { exam: 'TOEIC', ...data });
    const result = compareJob(job, [incomplete], now).checks[2];
    assert.equal(result.status, 'unknown');
    assert.equal(result.reasonCode, 'evidence_incomplete');
    assert.deepEqual(result.evidenceSpecIds, []);
    assert.equal(compareJob(job, [spec('low', SpecType.LANGUAGE_SCORE, { exam: 'TOEIC', score: 650 }), incomplete], now).checks[2].status, 'unknown');
  }
});

test('language grades are not invented as numbers and generic other exams never cross-match', () => {
  const job = comparisonJob({ requirements: [{ kind: 'language_score', name: 'OPIc', required: false }] });
  const result = compareJob(job, [spec('opic', SpecType.LANGUAGE_SCORE, { exam: 'OPIc', grade: 'IH' })], now).checks[2];
  assert.equal(result.status, 'unknown');
  assert.equal(result.reasonCode, 'condition_missing');
  job.requirements = [{ kind: 'language_score', name: '기타', minimumScore: 100, required: false }];
  assert.equal(compareJob(job, [spec('other', SpecType.LANGUAGE_SCORE, { exam: '기타', score: 200 })], now).checks[2].reasonCode, 'language_exam_ambiguous');
});

test('experience evidence excludes fully covered, zero-length, invalid and unrecognized work periods', () => {
  const job = comparisonJob();
  const work = (id: string, startedMonth: string, endedMonth: string, employmentType = '정규직') =>
    spec(id, SpecType.WORK_EXPERIENCE, { employmentType, startedMonth, endedMonth });
  const records = [
    work('main', '2024-01', '2026-02'), work('duplicate', '2025-01', '2026-01'),
    work('short', '2024-01', '2024-02'), work('reversed', '2026-01', '2024-01'),
    work('future', '2027-01', '2028-01'), work('invalid', '2024-13', '2026-01'),
    work('intern', '2020-01', '2026-01', '인턴'),
    spec('bad-employment-type', SpecType.WORK_EXPERIENCE, { employmentType: ['정규직'], startedMonth: '2020-01', endedMonth: '2026-01' }),
    spec('incomplete', SpecType.WORK_EXPERIENCE, { employmentType: '정규직', startedMonth: '2020-01' }),
  ];
  for (const ordered of [records, [...records].reverse()]) {
    const result = compareJob(job, ordered, now).checks[1];
    assert.equal(result.status, 'confirmed');
    assert.deepEqual(result.evidenceSpecIds, ['main']);
    assert.ok(result.reason.includes('24개월'));
  }
  const partial = compareJob(job, [work('partial', '2025-01', '2026-01')], now).checks[1];
  assert.equal(partial.status, 'unknown');
  assert.equal(partial.reasonCode, 'evidence_incomplete');
  assert.deepEqual(partial.evidenceSpecIds, ['partial']);
});

test('ongoing and future-ended work cannot count beyond the Korean current month', () => {
  const job = comparisonJob({ minExperienceMonths: 1 });
  const endings: Record<string, string | boolean>[] = [{ ongoing: true }, { endedMonth: '2028-12' }];
  for (const data of endings) {
    const work = spec('work', SpecType.WORK_EXPERIENCE, { employmentType: '계약직', startedMonth: '2026-08', ...data });
    assert.equal(compareJob(job, [work], new Date('2026-09-30T14:59:59Z')).checks[1].status, 'unknown');
    assert.equal(compareJob(job, [work], new Date('2026-09-30T15:00:00Z')).checks[1].status, 'confirmed');
  }
});

test('unspecified and entry-level career criteria never infer a total career of zero', () => {
  for (const overrides of [
    { experienceLevel: null }, { experienceLevel: ExperienceLevel.ENTRY },
    { minExperienceMonths: null }, { minExperienceMonths: 0 },
  ]) {
    assert.equal(compareJob(comparisonJob(overrides), [], now).checks[1].status, 'unknown');
  }
  const any = compareJob(comparisonJob({ experienceLevel: ExperienceLevel.ANY }), [], now).checks[1];
  assert.equal(any.status, 'not_required');
  assert.equal(any.reasonCode, 'condition_not_required');
});
