import 'reflect-metadata';
import * as assert from 'node:assert/strict';
import { randomUUID } from 'node:crypto';
import { test } from 'node:test';
import { mkdir, writeFile } from 'node:fs/promises';
import { dirname, resolve } from 'node:path';
import { ValidationPipe } from '@nestjs/common';
import { NestFactory } from '@nestjs/core';
import { config } from 'dotenv';
import { DataSource } from 'typeorm';
import { AppModule } from '../src/app.module';
import { CareerService } from '../src/career/career.service';
import { UserProfileEntity } from '../src/users/entities/user-profile.entity';

test('PostgreSQL career: authenticated preferences, atomic preservation, isolation, fresh analysis and no external AI', { skip: process.env.RUN_DB_TESTS !== 'true' }, async () => {
  config({ quiet: true });
  const original = new URL(process.env.DATABASE_URL!);
  assert.ok(['localhost', '127.0.0.1'].includes(original.hostname), 'Only an isolated local database may be used.');
  const name = `specmoa_career_test_${randomUUID().replaceAll('-', '')}`;
  assert.match(name, /^specmoa_career_test_[a-f0-9]{32}$/);
  const maintenance = new URL(original); maintenance.pathname = '/postgres';
  const admin = await new DataSource({ type: 'postgres', url: maintenance.toString() }).initialize();
  const scratch = new URL(original); scratch.pathname = `/${name}`;
  const previous = { ...process.env };
  let created = false;
  let app: Awaited<ReturnType<typeof NestFactory.create>> | undefined;
  let externalCalls = 0;
  const nativeFetch = globalThis.fetch;
  try {
    await admin.query(`CREATE DATABASE "${name}"`); created = true;
    process.env.DATABASE_URL = scratch.toString(); process.env.NODE_ENV = 'test';
    process.env.DB_SCHEMA = 'public'; process.env.DB_SYNC = 'true'; process.env.DB_SSL = 'false';
    process.env.JWT_SECRET = 'isolated-career-integration-test-secret';
    // Even an enabled demo/key must not make real career data leave the server.
    process.env.AI_DEMO_ENABLED = 'true'; process.env.GEMINI_API_KEY = 'test-key-never-sent';
    process.env.JOBS_SOURCE = 'demo';
    app = await NestFactory.create(AppModule, { logger: false });
    app.useGlobalPipes(new ValidationPipe({ transform: true, whitelist: true, forbidNonWhitelisted: true }));
    await app.listen(0, '127.0.0.1');
    const base = await app.getUrl();
    globalThis.fetch = ((input: Parameters<typeof fetch>[0], init?: Parameters<typeof fetch>[1]) => {
      const url = new URL(typeof input === 'string' || input instanceof URL ? input : input.url);
      if (url.origin !== base) { externalCalls++; throw new Error('External requests are forbidden in career preparation.'); }
      return nativeFetch(input, init);
    }) as typeof fetch;
    const request = (path: string, token?: string, body?: unknown, method = body === undefined ? 'GET' : 'PATCH', extra: Record<string, string> = {}) => fetch(`${base}${path}`, {
      method, headers: { 'Content-Type': 'application/json', ...(token ? { Authorization: `Bearer ${token}` } : {}), ...extra },
      ...(body === undefined ? {} : { body: JSON.stringify(body) }),
    });
    for (const path of ['/career/occupations', '/career/preferences', '/career/analysis-context']) {
      assert.equal((await request(path)).status, 401);
      assert.equal((await request(path, 'forged')).status, 401);
    }
    assert.equal((await request('/career/preferences', undefined, { desiredOccupations: ['backend'] })).status, 401);
    const register = async (email: string) => {
      const response = await request('/auth/register', undefined, { email, displayName: '격리 테스트', password: 'Career-Test-2026!' }, 'POST');
      assert.equal(response.status, 201);
      return response.json();
    };
    const a = await register('career-a@test.local');
    const b = await register('career-b@test.local');
    const dataSource = app.get(DataSource);
    const profiles = dataSource.getRepository(UserProfileEntity);
    const service = app.get(CareerService);
    await service.analysisContext(a.user.id);
    const initialResponse = await request('/career/analysis-context', a.accessToken);
    const initial = await initialResponse.json();
    assert.equal(initialResponse.status, 200, JSON.stringify(initial));
    assert.equal(initial.summary.totalSpecs, 0);
    assert.equal(initial.summary.byType.length, 8);
    assert.equal(initial.preferences.status, 'unset');
    assert.deepEqual(initial.specs, []);
    assert.equal(initial.privacy.mode, 'server_only');
    assert.equal(initial.privacy.externalAiTransmissionAllowed, false);
    assert.equal(initial.privacy.userProvidedTextMayContainPersonalData, true);
    assert.equal(await profiles.count(), 0, 'Reads must not create empty profiles.');
    const options = await (await request('/career/occupations', a.accessToken)).json();
    assert.equal(options.items.length, 10);

    for (const body of [[], null, 'backend', {}, { desiredOccupations: null }, { desiredOccupations: ['unknown'] }, { desiredOccupations: ['backend', 'backend'] },
      { desiredOccupations: ['backend'], userId: b.user.id }, { desiredOccupations: ['backend'], consent: true },
      { desiredOccupations: 'backend' }]) {
      assert.equal((await request('/career/preferences', a.accessToken, body)).status, 400);
    }
    for (const path of ['/career/preferences', '/career/analysis-context', '/career/occupations']) {
      assert.equal((await request(`${path}?userId=${a.user.id}`, b.accessToken)).status, 400);
    }

    // Two first saves must resolve to one profile, not duplicate rows or unique-key errors.
    const simultaneous = await Promise.all([
      request('/career/preferences', a.accessToken, { desiredOccupations: ['backend'] }),
      request('/career/preferences', a.accessToken, { desiredOccupations: ['mobile'] }),
    ]);
    assert.deepEqual(simultaneous.map(response => response.status), [200, 200]);
    assert.equal(await profiles.count({ where: { user: { id: a.user.id } } }), 1);
    const profile = await profiles.findOneByOrFail({ user: { id: a.user.id } });
    profile.preferences.notifications = { enabled: false };
    profile.nickname = '유지할 닉네임';
    await profiles.save(profile);
    const update = await request('/career/preferences', a.accessToken, { desiredOccupations: ['backend', 'data'] }, 'PATCH', { 'x-user-id': b.user.id });
    assert.equal(update.status, 200);
    assert.equal(update.headers.get('cache-control'), 'no-store');
    const saved = await update.json();
    assert.equal(saved.status, 'set');
    assert.deepEqual(saved.desiredOccupations, ['backend', 'data']);
    assert.ok(Number.isFinite(Date.parse(saved.updatedAt)));
    const reloaded = await profiles.findOneByOrFail({ user: { id: a.user.id } });
    assert.deepEqual(reloaded.preferences.notifications, { enabled: false });
    assert.equal(reloaded.nickname, '유지할 닉네임');
    assert.deepEqual(await service.preferences(a.user.id), saved, 'A fresh DB read must reproduce persisted preferences.');
    assert.equal((await (await request('/career/preferences', b.accessToken)).json()).status, 'unset');
    const empty = await (await request('/career/preferences', a.accessToken, { desiredOccupations: [] })).json();
    assert.equal(empty.status, 'unset');
    assert.deepEqual(empty.desiredOccupations, []);

    const create = async (type: string, data: object) => {
      const response = await request('/specs', a.accessToken, { type, data }, 'POST');
      assert.equal(response.status, 201);
      return response.json();
    };
    const project = await create('project', { name: 'A 전용 프로젝트', skills: ['NestJS'], action: '서버를 구현함', repositoryUrl: 'https://example.com/PRIVATE' });
    const certificate = await create('certification', { name: 'A 전용 자격', certificateNumber: 'PRIVATE-CERT-001' });
    const blank = await create('language_score', {});
    const contextResponse = await request('/career/analysis-context', a.accessToken);
    assert.equal(contextResponse.headers.get('cache-control'), 'no-store');
    const context = await contextResponse.json();
    assert.equal(context.summary.totalSpecs, 3);
    assert.deepEqual(context.summary.byType.find((group: { type: string }) => group.type === 'project'), { type: 'project', total: 1, available: 1, partial: 0, empty: 0 });
    const source = context.specs.find((spec: { specId: string }) => spec.specId === project.id);
    assert.equal(source.updatedAt, project.updatedAt);
    assert.equal(source.verification, 'unverified');
    assert.ok(source.facts.some((fact: { path: string; value: unknown }) => fact.path === 'data.action' && fact.value === '서버를 구현함'));
    assert.equal(context.specs.find((spec: { specId: string }) => spec.specId === blank.id).status, 'empty');
    assert.doesNotMatch(JSON.stringify(context.specs), /PRIVATE/);
    assert.equal(context.preferences.status, 'unset', 'A backend project must not infer a desired occupation.');
    const other = await (await request('/career/analysis-context', b.accessToken, undefined, 'GET', { 'x-user-id': a.user.id })).json();
    assert.deepEqual(other.specs, []);
    assert.equal(other.summary.totalSpecs, 0);
    assert.doesNotMatch(JSON.stringify(other), /A 전용|PRIVATE/);

    const change = await request(`/specs/${project.id}`, a.accessToken, { data: { action: '수정한 실제 내용' } });
    assert.equal(change.status, 200);
    const fresh = await (await request('/career/analysis-context', a.accessToken)).json();
    assert.equal(JSON.stringify(fresh).includes('수정한 실제 내용'), true);
    assert.equal(JSON.stringify(fresh).includes('서버를 구현함'), false);
    assert.equal((await request(`/specs/${certificate.id}`, a.accessToken, undefined, 'DELETE')).status, 200);
    const afterDelete = await (await request('/career/analysis-context', a.accessToken)).json();
    assert.equal(afterDelete.summary.totalSpecs, 2);
    assert.equal(JSON.stringify(afterDelete).includes(certificate.id), false);

    // A pre-existing malformed setting is reported, not guessed or returned as raw data.
    reloaded.preferences = { other: 'keep', career: { version: 'future', desiredOccupations: ['backend'], private: 'SECRET' } };
    await profiles.save(reloaded);
    assert.equal((await service.preferences(a.user.id)).status, 'needs_review');
    await request('/career/preferences', a.accessToken, { desiredOccupations: ['safety'] });
    assert.deepEqual((await profiles.findOneByOrFail({ user: { id: a.user.id } })).preferences.other, 'keep');

    if (process.env.EXPORT_CAREER_CONTRACT === 'true') {
      // Export only synthetic responses from this guarded scratch DB; never export tokens or real user data.
      await create('certification', { name: '가상 자격', issuer: '가상 기관', acquiredOn: '2025-01-01',
        result: '합격', grade: '1급', lifetime: false, expiresOn: '2030-01-01', keywords: ['SQL'],
        certificateNumber: 'NEVER-EXPORTED', reminders: [7] });
      await create('education_record', { academicStatus: '졸업', degree: '학사', school: '가상 대학교',
        major: '컴퓨터공학', hasAdditionalMajor: true, additionalMajor: '통계학', additionalMajorType: '부전공',
        gpaScale: 4.5, gpa: 0, majorGpa: 3.5 });
      await create('award', { name: '가상 공모전', organizer: '가상 기관', prize: '우수상', awardedOn: '2025-01-01',
        participation: '팀', role: '개발', projectName: '가상 프로젝트', contribution: 'API 구현',
        keywords: ['TypeScript'], relatedUrl: 'https://example.com/NEVER-EXPORTED' });
      await create('work_experience', { company: '가상 회사', employmentType: '인턴', departmentRole: '개발',
        startedMonth: '2024-01', endedMonth: '2024-06', ongoing: false, summary: '업무 요약',
        achievements: '성과 원문', troubleshooting: '문제 해결 원문' });
      await create('external_activity', { name: '가상 활동', organizer: '가상 기관', activityType: '연합 동아리/학회',
        startedMonth: '2024-01', ongoing: true, role: '운영', description: '활동 내용', awards: '가상 수상' });
      await create('training', { name: '가상 교육', institution: '가상 기관', trainingType: '온라인 코스/직무교육',
        hours: 40, startedOn: '2025-01-01', completedOn: '2025-02-01', skills: ['SQL'],
        summary: '학습 내용', projectName: '교육 프로젝트', projectRole: '개발', projectUrl: 'https://example.com/NEVER-EXPORTED' });
      assert.equal((await request(`/specs/${project.id}`, a.accessToken, { data: { projectType: '사이드 프로젝트',
        startedMonth: '2024-01', endedMonth: '2024-12', ongoing: false, role: '개발', teamSize: '2~4인 팀',
        situation: '문제 상황', task: '목표 원문', action: '수정한 실제 내용', result: '결과 원문' } })).status, 200);
      assert.equal((await request(`/specs/${blank.id}`, a.accessToken, { data: { exam: 'TOEIC', score: 0,
        grade: '사용자 입력 등급', testedOn: '2025-01-01', issuer: '가상 기관', registrationNumber: 'NEVER-EXPORTED', reminder: true } })).status, 200);
      const preferenceResponse = await request('/career/preferences', a.accessToken, { desiredOccupations: ['backend', 'mobile'] });
      assert.equal(preferenceResponse.status, 200);
      const exportResponse = await request('/career/analysis-context', a.accessToken);
      assert.equal(exportResponse.status, 200);
      const exported = await exportResponse.json();
      assert.equal(exported.summary.totalSpecs, 8);
      assert.equal(exported.summary.byType.every((group: { total: number }) => group.total === 1), true);
      assert.doesNotMatch(JSON.stringify(exported.specs), /NEVER-EXPORTED|PRIVATE/);
      const output = resolve(__dirname, '../../.buildlog/career-contract.json');
      await mkdir(dirname(output), { recursive: true });
      await writeFile(output, JSON.stringify({ source: 'isolated-postgres-http-fixture', catalog: options,
        preferences: await preferenceResponse.json(), context: exported, emptyContext: initial,
        afterDelete, deletedSpecId: certificate.id, updatedSpecId: project.id }), 'utf8');
    }
    assert.equal(externalCalls, 0, 'Real profile preparation must not call Gemini or any external service.');
  } finally {
    globalThis.fetch = nativeFetch;
    if (app) await app.close();
    for (const key of Object.keys(process.env)) if (!(key in previous)) delete process.env[key];
    Object.assign(process.env, previous);
    if (created) await admin.query(`DROP DATABASE "${name}" WITH (FORCE)`);
    await admin.destroy();
  }
});
