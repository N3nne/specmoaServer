import 'reflect-metadata';
import * as assert from 'node:assert/strict';
import { randomUUID } from 'node:crypto';
import { test } from 'node:test';
import { config } from 'dotenv';
import { DataSource } from 'typeorm';
import { ValidationPipe } from '@nestjs/common';
import { NestFactory } from '@nestjs/core';
import { AppModule } from '../src/app.module';
import { AddJobPostings1792627200000 } from '../src/database/migrations/1792627200000-AddJobPostings';
import { ListJobsDto } from '../src/jobs/dto/list-jobs.dto';
import { JobPostingEntity } from '../src/jobs/entities/job-posting.entity';
import { importJobs } from '../src/jobs/job-import';
import { JobsService } from '../src/jobs/jobs.service';
import { DemoJobSource } from '../src/jobs/providers/demo-job.source';
import { UserSpecEntity } from '../src/specs/entities/user-spec.entity';

test('PostgreSQL jobs: migration, idempotent seed, provider replacement, filters, ownership and missing-data comparisons', { skip: process.env.RUN_DB_TESTS !== 'true' }, async () => {
  config({ quiet: true });
  const original = new URL(process.env.DATABASE_URL!);
  assert.ok(['localhost', '127.0.0.1'].includes(original.hostname), 'Only an isolated local database may be used.');
  const name = `specmoa_jobs_test_${randomUUID().replaceAll('-', '')}`;
  assert.match(name, /^specmoa_jobs_test_[a-f0-9]{32}$/);
  const maintenance = new URL(original); maintenance.pathname = '/postgres';
  const admin = await new DataSource({ type: 'postgres', url: maintenance.toString() }).initialize();
  const scratch = new URL(original); scratch.pathname = `/${name}`;
  const previous = { ...process.env };
  let database: DataSource | undefined;
  let app: Awaited<ReturnType<typeof NestFactory.create>> | undefined;
  let created = false;
  try {
    await admin.query(`CREATE DATABASE "${name}"`); created = true;
    database = await new DataSource({ type: 'postgres', url: scratch.toString(), entities: [JobPostingEntity] }).initialize();
    const runner = database.createQueryRunner();
    await runner.startTransaction();
    try { await new AddJobPostings1792627200000().up(runner); await runner.commitTransaction(); }
    catch (error) { await runner.rollbackTransaction(); throw error; }
    finally { await runner.release(); }

    const repository = database.getRepository(JobPostingEntity);
    const source = new DemoJobSource();
    const now = new Date();
    assert.equal((await importJobs(repository, source, now)).imported, 40);
    const before = (await repository.find()).map(item => [item.externalId, item.id]).sort();
    await importJobs(repository, source, now);
    assert.equal(await repository.count(), 40);
    assert.deepEqual((await repository.find()).map(item => [item.externalId, item.id]).sort(), before);
    const originalItem = (await source.load(now))[0];
    await importJobs(repository, { ...source, load: async () => [{ ...originalItem, salaryText: '수정된 가상 연봉' }] }, now);
    const updated = await repository.findOneByOrFail({ source: 'demo', externalId: originalItem.externalId });
    assert.equal(updated.salaryText, '수정된 가상 연봉');
    assert.equal(updated.id, before.find(([externalId]) => externalId === originalItem.externalId)![1]);
    await importJobs(repository, source, now);

    // A stand-in external adapter uses the same model; it does not inherit invented demo details.
    const externalSource = {
      source: 'test_feed', synthetic: false, notice: '격리 테스트 전용 외부 응답', datasetVersion: null,
      load: async () => [{ ...originalItem, title: '테스트 외부 공고', description: null, requirements: null,
        educationLevel: null, experienceLevel: null, sourceUrl: 'https://example.com/jobs/test' }],
    };
    await importJobs(repository, externalSource, now);
    assert.equal(await repository.count(), 41);

    process.env.DATABASE_URL = scratch.toString(); process.env.NODE_ENV = 'test';
    process.env.DB_SCHEMA = 'public'; process.env.DB_SYNC = 'true'; process.env.DB_SSL = 'false';
    process.env.JWT_SECRET = 'isolated-jobs-integration-test-secret'; process.env.JOBS_SOURCE = 'demo';
    app = await NestFactory.create(AppModule, { logger: false });
    app.useGlobalPipes(new ValidationPipe({ transform: true, whitelist: true, forbidNonWhitelisted: true }));
    await app.listen(0, '127.0.0.1');
    const base = await app.getUrl();
    const request = async (path: string, token?: string, body?: object, method = body ? 'POST' : 'GET') => fetch(`${base}${path}`, {
      method, headers: { 'Content-Type': 'application/json', ...(token ? { Authorization: `Bearer ${token}` } : {}) },
      ...(body ? { body: JSON.stringify(body) } : {}),
    });
    assert.equal((await request('/jobs')).status, 401);
    const a = await (await request('/auth/register', undefined, { email: 'jobs-a@test.local', displayName: '사용자 A', password: 'Jobs-Test-2026!' })).json();
    const b = await (await request('/auth/register', undefined, { email: 'jobs-b@test.local', displayName: '사용자 B', password: 'Jobs-Test-2026!' })).json();
    const list = await (await request('/jobs?limit=100', a.accessToken)).json();
    assert.equal(list.total, 35);
    assert.equal(list.items.length, 35);
    assert.equal((await request('/jobs/demo/specmoa-demo-v1-001')).status, 401);
    const demoDetail = await (await request('/jobs/demo/specmoa-demo-v1-001', a.accessToken)).json();
    assert.equal(demoDetail.id, updated.id);
    assert.equal(demoDetail.externalId, 'specmoa-demo-v1-001');
    assert.equal(demoDetail.synthetic, true);
    assert.equal(demoDetail.canApply, false);
    assert.equal((await request('/jobs/demo/specmoa-demo-v1-999', a.accessToken)).status, 404);
    assert.equal((await request('/jobs/demo/not-a-demo', a.accessToken)).status, 404);
    assert.equal(list.synthetic, true);
    assert.equal(list.items.every((item: JobPostingEntity & { canApply: boolean }) => item.synthetic && !item.canApply && item.sourceUrl === null), true);
    assert.equal((await (await request('/jobs?status=all&limit=100', a.accessToken)).json()).total, 40);
    assert.equal((await (await request('/jobs?status=closed', a.accessToken)).json()).total, 4);
    assert.equal((await (await request('/jobs?status=upcoming', a.accessToken)).json()).total, 1);
    const first = await (await request('/jobs?limit=3', a.accessToken)).json();
    const next = await (await request('/jobs?limit=3&offset=3', a.accessToken)).json();
    assert.equal(new Set([...first.items, ...next.items].map((item: JobPostingEntity) => item.id)).size, 6);
    const facets = await (await request('/jobs/facets?status=all', a.accessToken)).json();
    assert.equal(facets.total, 40);
    assert.equal(facets.occupations.length, 10);
    assert.equal(facets.regions.length, 8);
    assert.equal(facets.employmentTypes.reduce((sum: number, facet: { count: number }) => sum + facet.count, 0), 40);
    const filtered = await (await request('/jobs?occupation=backend&employmentType=full_time&q=NestJS', a.accessToken)).json();
    assert.equal(filtered.total, 2);
    assert.equal((await (await request('/jobs?q=%25', a.accessToken)).json()).total, 0);
    assert.equal((await (await request('/jobs?q=%27%20OR%201%3D1--', a.accessToken)).json()).total, 0);
    const deadline = await (await request('/jobs?sort=deadline&limit=100', a.accessToken)).json();
    const dated = deadline.items.filter((item: JobPostingEntity) => item.closesAt !== null).map((item: JobPostingEntity) => String(item.closesAt));
    assert.deepEqual([...dated].sort(), dated);
    assert.equal(deadline.items.at(-1).closesAt, null);
    for (const query of ['limit=0', 'limit=101', 'offset=-1', 'status=bad', 'source=saramin', `userId=${b.user.id}`]) {
      assert.equal((await request(`/jobs?${query}`, a.accessToken)).status, 400);
    }
    assert.equal((await request('/jobs/not-a-uuid', a.accessToken)).status, 400);
    assert.equal((await request(`/jobs/${randomUUID()}`, a.accessToken)).status, 404);

    const backend = await repository.findOneByOrFail({ source: 'demo', externalId: originalItem.externalId });
    const saved = await (await request('/specs', a.accessToken, { type: 'project', data: { name: 'A 비공개 프로젝트', skills: ['TypeScript', 'NestJS'] } })).json();
    const own = await (await request(`/jobs/${backend.id}/match`, a.accessToken)).json();
    assert.equal(own.comparison.checks.some((check: { evidenceSpecIds: string[] }) => check.evidenceSpecIds.includes(saved.id)), true);
    assert.equal(own.comparison.method, 'rules-v2');
    assert.ok(Number.isFinite(Date.parse(own.comparison.comparedAt)));
    assert.equal(own.comparison.checks.every((check: { reason: string; reasonCode: string }) => check.reason && check.reasonCode), true);

    const compare = async (id = backend.id, token = a.accessToken) => {
      const response = await request(`/jobs/${id}/match`, token);
      assert.equal(response.status, 200);
      return (await response.json()).comparison;
    };
    const createSpec = async (type: string, data: object) => {
      const response = await request('/specs', a.accessToken, { type, data });
      assert.equal(response.status, 201);
      return response.json();
    };
    const education = await createSpec('education_record', { degree: '전문학사', academicStatus: '졸업' });
    const lowerDegree = (await compare()).checks[0];
    assert.equal(lowerDegree.status, 'not_confirmed');
    assert.equal(lowerDegree.reasonCode, 'below_minimum');
    assert.deepEqual(lowerDegree.evidenceSpecIds, [education.id]);
    assert.equal((await request(`/specs/${education.id}`, a.accessToken, { data: { degree: '학사' } }, 'PATCH')).status, 200);
    assert.equal((await compare()).checks[0].status, 'confirmed');
    assert.equal((await request(`/specs/${education.id}`, a.accessToken, undefined, 'DELETE')).status, 200);
    assert.equal((await compare()).checks[0].status, 'unknown');

    const certificate = await createSpec('certification', { name: '정보처리기사', acquiredOn: '2020-01-01', lifetime: true });
    const certificateCheck = (await compare()).checks.find((check: { kind: string }) => check.kind === 'certification');
    assert.equal(certificateCheck.status, 'confirmed');
    assert.deepEqual(certificateCheck.evidenceSpecIds, [certificate.id]);
    const language = await createSpec('language_score', { exam: 'TOEIC', score: 650 });
    const languageCheck = (await compare()).checks.find((check: { kind: string }) => check.kind === 'language_score');
    assert.equal(languageCheck.status, 'not_confirmed');
    assert.deepEqual(languageCheck.evidenceSpecIds, [language.id]);
    assert.equal((await request(`/specs/${language.id}`, b.accessToken, { data: { score: 850 } }, 'PATCH')).status, 404);
    assert.equal((await request(`/specs/${language.id}`, a.accessToken, { data: { score: 850 } }, 'PATCH')).status, 200);
    assert.equal((await compare()).checks.find((check: { kind: string }) => check.kind === 'language_score').status, 'confirmed');
    assert.equal((await request(`/specs/${language.id}`, a.accessToken, undefined, 'DELETE')).status, 200);
    assert.equal((await compare()).checks.find((check: { kind: string }) => check.kind === 'language_score').status, 'unknown');

    const experienced = await repository.findOneByOrFail({ source: 'demo', externalId: 'specmoa-demo-v1-003' });
    const work = await createSpec('work_experience', { company: 'A 비공개 직장', employmentType: '정규직', startedMonth: '2020-01', endedMonth: '2024-02' });
    const overlapping = await createSpec('work_experience', { company: 'A 중복 기간 직장', employmentType: '계약직', startedMonth: '2021-01', endedMonth: '2022-01' });
    const experienceCheck = (await compare(experienced.id)).checks[1];
    assert.equal(experienceCheck.status, 'confirmed');
    assert.deepEqual(experienceCheck.evidenceSpecIds, [work.id]);
    assert.equal(experienceCheck.evidenceSpecIds.includes(overlapping.id), false);
    for (const id of [work.id, overlapping.id]) {
      assert.equal((await request(`/specs/${id}`, a.accessToken, undefined, 'DELETE')).status, 200);
    }
    assert.equal((await compare(experienced.id)).checks[1].status, 'unknown');
    const other = await (await request(`/jobs/${backend.id}/match`, b.accessToken)).json();
    assert.equal(other.comparison.checks.every((check: { evidenceSpecIds: string[] }) => check.evidenceSpecIds.length === 0), true);
    assert.equal(other.comparison.required.not_confirmed, 0);
    assert.equal(JSON.stringify(other).includes(saved.id), false);
    assert.equal(JSON.stringify(other).includes(certificate.id), false);
    assert.equal(JSON.stringify(other).includes('비공개'), false);
    const spoofed = await (await request(`/jobs/${backend.id}/match?userId=${a.user.id}`, b.accessToken)).json();
    assert.equal(spoofed.comparison.checks.every((check: { evidenceSpecIds: string[] }) => check.evidenceSpecIds.length === 0), true);
    assert.equal((await request(`/jobs/${backend.id}/match`)).status, 401);
    const missing = await repository.findOneByOrFail({ source: 'demo', externalId: 'specmoa-demo-v1-004' });
    const detail = await (await request(`/jobs/${missing.id}`, a.accessToken)).json();
    assert.equal(detail.description, null);
    assert.equal(detail.requirements, null);
    assert.equal(detail.requirementsOrigin, 'unavailable');

    const external = await repository.findOneByOrFail({ source: 'test_feed', externalId: originalItem.externalId });
    assert.equal((await request(`/jobs/${external.id}`, a.accessToken)).status, 404);
    const externalService = new JobsService(repository, app.get(DataSource).getRepository(UserSpecEntity), externalSource);
    const externalDetail = await externalService.detail(external.id);
    assert.equal(externalDetail.synthetic, false);
    assert.equal(externalDetail.description, null);
    assert.equal(externalDetail.educationLevel, null);
    assert.equal(externalDetail.requirementsOrigin, 'unavailable');
    assert.equal(externalDetail.sourceUrl, 'https://example.com/jobs/test');
    const externalList = await externalService.list(new ListJobsDto());
    assert.equal(externalList.total, 1);
    assert.equal(externalList.items.length, 1);
  } finally {
    if (app) await app.close();
    if (database?.isInitialized) await database.destroy();
    for (const key of Object.keys(process.env)) if (!(key in previous)) delete process.env[key];
    Object.assign(process.env, previous);
    if (created) await admin.query(`DROP DATABASE "${name}" WITH (FORCE)`);
    await admin.destroy();
  }
});
