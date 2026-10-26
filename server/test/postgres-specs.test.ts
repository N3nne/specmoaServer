import 'reflect-metadata';
import * as assert from 'node:assert/strict';
import { randomUUID } from 'node:crypto';
import { test } from 'node:test';
import { config } from 'dotenv';
import { DataSource } from 'typeorm';
import { ValidationPipe } from '@nestjs/common';
import { NestFactory } from '@nestjs/core';
import { AppModule } from '../src/app.module';
import { AddUserSpecs1791763200000 } from '../src/database/migrations/1791763200000-AddUserSpecs';
import { AddAuthSessions1792195200000 } from '../src/database/migrations/1792195200000-AddAuthSessions';
import { JwtService } from '@nestjs/jwt';

test('PostgreSQL: migration preserves legacy records; login, CRUD and study deletion work', { skip: process.env.RUN_DB_TESTS !== 'true' }, async () => {
  config({ quiet: true });
  const original = new URL(process.env.DATABASE_URL!);
  assert.ok(['localhost', '127.0.0.1'].includes(original.hostname), 'Integration tests only create an isolated local database.');
  const name = `specmoa_code_test_${randomUUID().replaceAll('-', '')}`;
  assert.match(name, /^specmoa_code_test_[a-f0-9]{32}$/);
  const maintenance = new URL(original); maintenance.pathname = '/postgres';
  const admin = await new DataSource({ type: 'postgres', url: maintenance.toString() }).initialize();
  const scratch = new URL(original); scratch.pathname = `/${name}`;
  let database: DataSource | undefined;
  let app: Awaited<ReturnType<typeof NestFactory.create>> | undefined;
  const previous = { ...process.env };
  let created = false;
  try {
    await admin.query(`CREATE DATABASE "${name}"`); created = true;
    database = await new DataSource({ type: 'postgres', url: scratch.toString() }).initialize();
    await database.query(`
      CREATE TABLE users (id uuid PRIMARY KEY, email varchar UNIQUE NOT NULL, "displayName" varchar NOT NULL, "authProvider" varchar NOT NULL DEFAULT 'local', "passwordHash" varchar, "createdAt" timestamp NOT NULL DEFAULT now(), "updatedAt" timestamp NOT NULL DEFAULT now());
      CREATE TABLE certifications (id uuid PRIMARY KEY, "externalSource" varchar NOT NULL, "externalId" varchar NOT NULL, name varchar NOT NULL, category varchar NOT NULL, organization varchar, "rawPayload" jsonb NOT NULL DEFAULT '{}', "createdAt" timestamp NOT NULL DEFAULT now(), "updatedAt" timestamp NOT NULL DEFAULT now());
      CREATE TYPE user_certifications_status_enum AS ENUM ('planned','in_progress','certified','archived');
      CREATE TABLE user_certifications (id uuid PRIMARY KEY, "userId" uuid, "certificationId" uuid, status user_certifications_status_enum NOT NULL, progress int NOT NULL DEFAULT 0, "certifiedOn" date, "targetExamDate" date, "certificateNumber" varchar, "preparationCategory" varchar, notes text, "createdAt" timestamp NOT NULL DEFAULT now(), "updatedAt" timestamp NOT NULL DEFAULT now());
      CREATE TABLE study_sessions (id uuid PRIMARY KEY, "userId" uuid, "certificationId" uuid, "startedAt" timestamptz NOT NULL, "endedAt" timestamptz, "durationSeconds" int NOT NULL DEFAULT 0, note text, "createdAt" timestamp NOT NULL DEFAULT now(), "updatedAt" timestamp NOT NULL DEFAULT now());
    `);
    const legacyUser = randomUUID(), cert = randomUUID(), acquired = randomUUID();
    await database.query('INSERT INTO users (id,email,"displayName") VALUES ($1,$2,$3)', [legacyUser, 'legacy@test.local', 'Legacy']);
    await database.query('INSERT INTO certifications (id,"externalSource","externalId",name,category,organization) VALUES ($1,$2,$3,$4,$5,$6)', [cert, 'test', 'legacy', '기존 자격증', '테스트', '테스트 기관']);
    await database.query('INSERT INTO user_certifications (id,"userId","certificationId",status,"certifiedOn","certificateNumber",notes) VALUES ($1,$2,$3,$4,$5,$6,$7)', [acquired, legacyUser, cert, 'certified', '2024-04-15', '0001-A', '보존해야 하는 메모']);
    await database.query('INSERT INTO user_certifications (id,"userId","certificationId",status,notes) VALUES ($1,$2,$3,$4,$5)', [randomUUID(), legacyUser, cert, 'planned', '준비 중 내역 보존']);
    await database.query('INSERT INTO study_sessions (id,"userId","certificationId","startedAt","durationSeconds") VALUES ($1,$2,$3,now(),60)', [randomUUID(), legacyUser, cert]);
    const runner = database.createQueryRunner();
    await runner.startTransaction();
    try {
      await new AddUserSpecs1791763200000().up(runner);
      await new AddAuthSessions1792195200000().up(runner);
      await runner.commitTransaction();
    }
    catch (error) { await runner.rollbackTransaction(); throw error; }
    finally { await runner.release(); }
    assert.equal((await database.query('SELECT * FROM user_specs')).length, 1);
    const migrated = (await database.query('SELECT * FROM user_specs'))[0];
    assert.equal(migrated.data.certificateNumber, '0001-A');
    assert.equal(migrated.data.lifetime, undefined);
    assert.equal((await database.query('SELECT * FROM user_certifications')).length, 2);
    assert.equal((await database.query('SELECT notes FROM user_certifications WHERE id=$1', [acquired]))[0].notes, '보존해야 하는 메모');
    assert.equal((await database.query('SELECT "specId" FROM study_sessions'))[0].specId, migrated.id);

    process.env.DATABASE_URL = scratch.toString();
    process.env.NODE_ENV = 'test'; process.env.DB_SCHEMA = 'public'; process.env.DB_SYNC = 'true'; process.env.DB_SSL = 'false';
    process.env.JWT_SECRET = 'isolated-integration-test-secret-only';
    app = await NestFactory.create(AppModule, { logger: false });
    app.useGlobalPipes(new ValidationPipe({ transform: true, whitelist: true, forbidNonWhitelisted: true }));
    await app.listen(0, '127.0.0.1');
    const base = await app.getUrl();
    const request = async (method: string, path: string, token?: string, body?: object) => fetch(`${base}${path}`, { method, headers: { 'Content-Type': 'application/json', ...(token ? { Authorization: `Bearer ${token}` } : {}) }, ...(body ? { body: JSON.stringify(body) } : {}) });
    assert.equal((await request('GET', '/health')).status, 200);
    const registration = await request('POST', '/auth/register', undefined, { email: 'new@test.local', displayName: '테스트 사용자', password: 'Prototype-Test-2026!' });
    assert.equal(registration.status, 201);
    const auth = await registration.json();
    assert.ok(auth.accessToken);
    assert.ok(auth.refreshToken);
    assert.equal(auth.expiresIn, 900);
    assert.equal(registration.headers.get('cache-control'), 'no-store');
    const storedSession = (await database.query('SELECT * FROM auth_sessions WHERE "userId"=$1', [auth.user.id]))[0];
    assert.equal(storedSession.tokenHash.length, 64);
    assert.notEqual(storedSession.tokenHash, auth.refreshToken);
    assert.equal(auth.accessToken.includes(auth.refreshToken), false);
    const login = await request('POST', '/auth/login', undefined, { email: 'new@test.local', password: 'Prototype-Test-2026!' });
    assert.ok((await login.json()).accessToken);
    const token = auth.accessToken;
    assert.equal((await request('GET', `/specs/${migrated.id}`, token)).status, 404);
    const response = await request('POST', '/specs', token, { type: 'certification', data: { name: '직접 등록', issuer: '개인 입력', certificateNumber: '0002' } });
    assert.equal(response.status, 201);
    const manual = await response.json();
    const linked = await request('POST', '/study-sessions', token, { specId: manual.id, startedAt: new Date(Date.now() - 60000).toISOString(), endedAt: new Date().toISOString(), durationSeconds: 60 });
    assert.equal(linked.status, 201);
    const free = await request('POST', '/study-sessions', token, { startedAt: new Date(Date.now() - 30000).toISOString(), endedAt: new Date().toISOString(), durationSeconds: 30 });
    assert.equal(free.status, 201);
    const forbiddenLink = await request('POST', '/study-sessions', token, { specId: migrated.id, startedAt: new Date().toISOString(), durationSeconds: 1 });
    assert.equal(forbiddenLink.status, 404);
    const summary = await (await request('GET', '/specs/summary', token)).json();
    assert.equal(summary.total, 1);
    assert.equal(summary.byType.certification, 1);
    assert.equal((await request('DELETE', `/specs/${manual.id}`, token)).status, 200);
    const sessions = await (await request('GET', '/study-sessions/summary', token)).json();
    assert.equal(sessions.totalSeconds, 30);
    assert.equal(sessions.recent.length, 1);
    assert.equal((await database.query('SELECT * FROM user_specs')).length, 1);

    // Real PostgreSQL row locking: only one of two concurrent refreshes may consume a token.
    const competing = await Promise.all([
      request('POST', '/auth/refresh', undefined, { refreshToken: auth.refreshToken }),
      request('POST', '/auth/refresh', undefined, { refreshToken: auth.refreshToken }),
    ]);
    assert.deepEqual(competing.map(item => item.status).sort(), [201, 401]);
    const rotated = await competing.find(item => item.status === 201)!.json();
    assert.notEqual(rotated.refreshToken, auth.refreshToken);
    assert.equal(rotated.user.id, auth.user.id);
    assert.equal(rotated.refreshExpiresAt, auth.refreshExpiresAt);
    assert.equal((await request('GET', '/specs', rotated.accessToken)).status, 200);
    assert.equal((await request('POST', '/auth/refresh', undefined, { refreshToken: auth.refreshToken })).status, 401);
    assert.equal((await request('POST', '/auth/refresh', undefined, { refreshToken: 'invalid' })).status, 400);
    assert.equal((await request('POST', '/auth/refresh', undefined, { refreshToken: rotated.refreshToken, userId: legacyUser })).status, 400);

    const payload = app.get(JwtService).decode(rotated.accessToken) as { sub: string; sid: string };
    const expiredAccess = await app.get(JwtService).signAsync({ sub: payload.sub, sid: payload.sid }, { expiresIn: -1 });
    assert.equal((await request('GET', '/specs', expiredAccess)).status, 401);
    const renewed = await (await request('POST', '/auth/refresh', undefined, { refreshToken: rotated.refreshToken })).json();
    assert.equal((await request('GET', '/specs', renewed.accessToken)).status, 200);
    assert.equal((await request('POST', '/auth/logout', undefined, { refreshToken: renewed.refreshToken })).status, 201);
    assert.equal((await request('GET', '/specs', renewed.accessToken)).status, 401);
    assert.equal((await request('GET', '/specs', token)).status, 401);
    assert.equal((await request('POST', '/auth/refresh', undefined, { refreshToken: renewed.refreshToken })).status, 401);
    assert.equal((await request('POST', '/auth/logout', undefined, { refreshToken: renewed.refreshToken })).status, 201);

    // Logging out this session must not log out a different device/session.
    const secondLogin = await (await request('POST', '/auth/login', undefined, { email: 'new@test.local', password: 'Prototype-Test-2026!' })).json();
    assert.equal((await request('GET', '/specs', secondLogin.accessToken)).status, 200);
    await database.query('UPDATE auth_sessions SET "expiresAt"=now() - interval \'1 second\' WHERE "userId"=$1', [auth.user.id]);
    assert.equal((await request('GET', '/specs', secondLogin.accessToken)).status, 401);
    assert.equal((await request('POST', '/auth/refresh', undefined, { refreshToken: secondLogin.refreshToken })).status, 401);
  } finally {
    if (app) await app.close();
    if (database?.isInitialized) await database.destroy();
    for (const key of Object.keys(process.env)) if (!(key in previous)) delete process.env[key];
    Object.assign(process.env, previous);
    if (created) await admin.query(`DROP DATABASE "${name}" WITH (FORCE)`);
    await admin.destroy();
  }
});
