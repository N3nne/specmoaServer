import 'reflect-metadata';
import * as assert from 'node:assert/strict';
import { randomUUID } from 'node:crypto';
import { test } from 'node:test';
import { validate } from 'class-validator';
import { CAREER_PREFERENCES_VERSION, readCareerPreferences } from '../src/career/career-preferences';
import { UpdateCareerPreferencesDto } from '../src/career/dto/update-career-preferences.dto';
import { prepareSpecAnalysis } from '../src/career/spec-analysis-context';
import { JOB_OCCUPATION_CODES, JOB_OCCUPATIONS } from '../src/jobs/job-occupations';
import { DemoJobSource } from '../src/jobs/providers/demo-job.source';
import { SpecData, SpecType } from '../src/specs/spec-types';

const updatedAt = new Date('2026-01-01T00:00:00Z');
const record = (type: SpecType, data: SpecData) => prepareSpecAnalysis({ id: randomUUID(), type, data, updatedAt });
const value = (result: ReturnType<typeof record>, field: string) => result.facts.find(fact => fact.field === field)?.value;

test('career preferences: optional selection, strict codes, explicit clearing and invalid stored versions', async () => {
  assert.equal(readCareerPreferences({}).status, 'unset');
  const valid = { version: CAREER_PREFERENCES_VERSION, desiredOccupations: ['backend', 'mobile'], updatedAt: updatedAt.toISOString() };
  const parsed = readCareerPreferences({ other: 'preserved', career: valid });
  assert.equal(parsed.status, 'set');
  assert.deepEqual(parsed.desiredOccupations, ['backend', 'mobile']);
  assert.equal(JSON.stringify(parsed).includes('preserved'), false);
  assert.equal(readCareerPreferences({ career: { ...valid, desiredOccupations: [] } }).status, 'unset');
  for (const career of [null, [], { ...valid, version: 'future' }, { ...valid, desiredOccupations: ['unknown'] },
    { ...valid, desiredOccupations: ['backend', 'backend'] }, { ...valid, updatedAt: 'bad' },
    { ...valid, updatedAt: '2026-10-26' }, { ...valid, updatedAt: '2026-02-30T00:00:00.000Z' }]) {
    assert.equal(readCareerPreferences({ career }).status, 'needs_review');
    assert.deepEqual(readCareerPreferences({ career }).desiredOccupations, []);
  }
  for (const codes of [[], ['backend'], JOB_OCCUPATION_CODES]) {
    assert.equal((await validate(Object.assign(new UpdateCareerPreferencesDto(), { desiredOccupations: codes }))).length, 0);
  }
  for (const codes of [undefined, null, '', {}, ['backend', 'backend'], ['unknown'], [1], [' backend'], Array(11).fill('backend')]) {
    assert.ok((await validate(Object.assign(new UpdateCareerPreferencesDto(), { desiredOccupations: codes }))).length > 0);
  }
  const jobs = await new DemoJobSource().load(updatedAt);
  assert.deepEqual([...new Set(jobs.map(job => job.occupation))].sort(), [...JOB_OCCUPATION_CODES].sort());
  for (const occupation of JOB_OCCUPATIONS) {
    assert.ok(jobs.some(job => job.occupation === occupation.code && job.keywords.includes(occupation.label)));
  }
});

test('analysis context: all eight optional types, real STAR fields and source provenance', () => {
  const examples: Record<SpecType, SpecData> = {
    certification: { name: '직접 입력 자격', issuer: '입력 기관', acquiredOn: '2025-01-01' },
    language_score: { exam: 'OPIc', grade: 'IH', testedOn: '2025-01-01' },
    education_record: { degree: '학사', academicStatus: '재학', gpaScale: 4.5, gpa: 3.5 },
    award: { name: '수상명', prize: '우수상', contribution: '담당 업무' },
    project: { name: '실제 프로젝트', skills: [' #NestJS ', 'NestJS'], situation: '문제', task: '목표', action: '구현', result: '결과', ongoing: true },
    work_experience: { company: '회사', departmentRole: '백엔드 인턴', ongoing: true },
    external_activity: { name: '활동', description: '실제 수행 업무' },
    training: { name: '교육', hours: 40, skills: ['SQL'], summary: '실습 내용' },
  };
  for (const type of Object.values(SpecType)) {
    const empty = record(type, {});
    assert.equal(empty.status, 'empty');
    assert.equal(empty.facts.length, 0);
    assert.ok(empty.missingContext.length > 0);
    const populated = record(type, examples[type]);
    assert.equal(populated.status, 'available', type);
    assert.equal(populated.verification, 'unverified');
    assert.equal(populated.updatedAt, updatedAt.toISOString());
    assert.ok(populated.facts.every(fact => fact.path === `data.${fact.field}`));
    assert.equal(populated.issues.length, 0);
  }
  const project = record(SpecType.PROJECT, examples.project);
  assert.equal(value(project, 'action'), '구현');
  assert.equal(value(project, 'result'), '결과');
  assert.deepEqual(value(project, 'skills'), ['NestJS']);
  assert.equal(value(project, 'description'), undefined);
});

test('analysis context: identifiers, URLs, unknown fields and raw titles do not enter facts', () => {
  const certificate = record(SpecType.CERTIFICATION, { name: '자격명', certificateNumber: 'SECRET-CERT', certificationId: randomUUID(), reminders: [7], unknown: 'SECRET-UNKNOWN' });
  const language = record(SpecType.LANGUAGE_SCORE, { exam: 'TOEIC', score: 750, registrationNumber: 'SECRET-EXAM', reminder: true });
  const project = record(SpecType.PROJECT, { name: '프로젝트', repositoryUrl: 'https://example.com/PRIVATE', demoUrl: 'https://example.com/PRIVATE', skills: ['SQL'] });
  assert.doesNotMatch(JSON.stringify([certificate, language, project]), /SECRET|PRIVATE|certificateNumber|registrationNumber|certificationId|repositoryUrl|demoUrl/);
  assert.equal(value(language, 'score'), 750);
  // Free text is intentionally NOT claimed to be anonymized; this endpoint stays local-only.
  const narrative = record(SpecType.PROJECT, { name: '프로젝트', action: '연락처가 포함될 수도 있는 사용자 원문' });
  assert.equal(value(narrative, 'action'), '연락처가 포함될 수도 있는 사용자 원문');
});

test('analysis context: incomplete scores, scales, bad legacy values and date ranges are not invented', () => {
  const language = record(SpecType.LANGUAGE_SCORE, { score: 0, grade: 'IH' });
  assert.equal(language.status, 'partial');
  assert.equal(value(language, 'score'), undefined);
  assert.equal(value(language, 'grade'), undefined);
  assert.equal(language.issues.filter(issue => issue.code === 'missing_context').length, 2);
  assert.equal(value(record(SpecType.LANGUAGE_SCORE, { exam: 'TOEIC', score: 0 }), 'score'), 0);
  assert.equal(value(record(SpecType.LANGUAGE_SCORE, { exam: 'TOEIC', score: 1000 }), 'score'), undefined);
  const education = record(SpecType.EDUCATION_RECORD, { gpa: 3.8 });
  assert.equal(value(education, 'gpa'), undefined);
  assert.ok(education.issues.some(issue => issue.code === 'missing_context'));
  assert.equal(value(record(SpecType.EDUCATION_RECORD, { gpaScale: 4.3, gpa: 4.5 }), 'gpa'), undefined);
  const legacy = record(SpecType.CERTIFICATION, { name: '  자격명  ', acquiredOn: '2025-02-30', result: 10, grade: '' });
  assert.equal(value(legacy, 'name'), '자격명');
  assert.equal(value(legacy, 'acquiredOn'), undefined);
  assert.equal(value(legacy, 'result'), undefined);
  assert.equal(legacy.issues.length, 2);
  const reversed = record(SpecType.PROJECT, { name: '기간 오류', startedMonth: '2025-12', endedMonth: '2025-01' });
  assert.equal(reversed.issues.filter(issue => issue.code === 'inconsistent_range').length, 2);
  assert.equal(value(reversed, 'startedMonth'), undefined);
  assert.equal(value(reversed, 'endedMonth'), undefined);
  assert.equal(value(record(SpecType.PROJECT, { ongoing: false }), 'ongoing'), false);
  const ongoing = record(SpecType.PROJECT, { ongoing: true, endedMonth: 'bad' });
  assert.equal(ongoing.missingFields.includes('endedMonth'), false);
  assert.equal(ongoing.issues.length, 0);
  const lifetime = record(SpecType.CERTIFICATION, { name: '자격명', lifetime: true, expiresOn: 'bad' });
  assert.equal(lifetime.issues.length, 0);
  assert.equal(lifetime.missingFields.includes('expiresOn'), false);
  assert.equal(value(record(SpecType.LANGUAGE_SCORE, { exam: 'TOEIC', score: 750, testedOn: '2020-01-01' }), 'testedOn'), '2020-01-01');
  assert.equal('expired' in lifetime, false);
});

test('analysis context: malformed records and unsupported types fail closed without affecting other records', () => {
  for (const data of [null, [], 'raw']) {
    const result = record(SpecType.PROJECT, data as unknown as SpecData);
    assert.equal(result.status, 'partial');
    assert.deepEqual(result.facts, []);
    assert.equal(result.issues[0].code, 'invalid_record');
  }
  const unsupported = record('future_type' as SpecType, { name: 'private' });
  assert.equal(unsupported.status, 'unsupported');
  assert.equal(JSON.stringify(unsupported).includes('private'), false);
});
