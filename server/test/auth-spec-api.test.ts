import 'reflect-metadata';
import * as assert from 'node:assert/strict';
import { test } from 'node:test';
import { randomUUID } from 'node:crypto';
import { NotFoundException, ValidationPipe } from '@nestjs/common';
import { APP_GUARD } from '@nestjs/core';
import { JwtService } from '@nestjs/jwt';
import { Test } from '@nestjs/testing';
import { getRepositoryToken } from '@nestjs/typeorm';
import { AuthGuard } from '../src/auth/auth.guard';
import { AuthSessionsService } from '../src/auth/auth-sessions.service';
import { getUserIdFromHeaders } from '../src/common/request-user';
import { CertificationEntity } from '../src/certifications/entities/certification.entity';
import { UserSpecEntity } from '../src/specs/entities/user-spec.entity';
import { SpecsController } from '../src/specs/specs.controller';
import { SpecsService } from '../src/specs/specs.service';
import { SpecType } from '../src/specs/spec-types';
import { UsersService } from '../src/users/users.service';

test('authenticated API: optional CRUD, token validation and ownership isolation', async () => {
  const userA: string = randomUUID(), userB: string = randomUUID();
  const sessionA = randomUUID(), sessionB = randomUUID();
  const rows: UserSpecEntity[] = [];
  const jwt = new JwtService({ secret: 'test-only-secret-not-used-in-production', signOptions: { expiresIn: '1h' } });
  const repository = {
    create: (value: Partial<UserSpecEntity>) => ({ ...value, id: randomUUID(), createdAt: new Date(), updatedAt: new Date() }),
    save: async (value: UserSpecEntity) => { const index = rows.findIndex(row => row.id === value.id); if (index < 0) rows.push(value); else rows[index] = value; return value; },
    findOneBy: async (where: Partial<UserSpecEntity>) => rows.find(row => Object.entries(where).every(([key, value]) => Reflect.get(row, key) === value)) ?? null,
    findAndCount: async ({ where, skip, take }: { where: Partial<UserSpecEntity>; skip: number; take: number }) => { const items = rows.filter(row => Object.entries(where).every(([key, value]) => Reflect.get(row, key) === value)); return [items.slice(skip, skip + take), items.length]; },
    delete: async ({ id, userId }: { id: string; userId: string }) => { const index = rows.findIndex(row => row.id === id && row.userId === userId); if (index >= 0) rows.splice(index, 1); },
  };
  const module = await Test.createTestingModule({
    controllers: [SpecsController],
    providers: [SpecsService, { provide: APP_GUARD, useClass: AuthGuard },
      { provide: JwtService, useValue: jwt },
      { provide: AuthSessionsService, useValue: { isActive: async (sid: string, sub: string) => sid === sessionA && sub === userA || sid === sessionB && sub === userB } },
      { provide: UsersService, useValue: { findById: async (id: string) => { if (![userA, userB].includes(id)) throw new NotFoundException('Missing user'); return { id }; } } },
      { provide: getRepositoryToken(UserSpecEntity), useValue: repository },
      { provide: getRepositoryToken(CertificationEntity), useValue: { findOneBy: async () => null } },
    ],
  }).compile();
  const app = module.createNestApplication({ logger: false });
  app.useGlobalPipes(new ValidationPipe({ transform: true, whitelist: true, forbidNonWhitelisted: true }));
  await app.listen(0, '127.0.0.1');
  const base = await app.getUrl();
  const a = await jwt.signAsync({ sub: userA, sid: sessionA });
  const b = await jwt.signAsync({ sub: userB, sid: sessionB });
  const request = async (method: string, path: string, token?: string, body?: object, extra?: Record<string, string>) => fetch(`${base}${path}`, { method, headers: { 'Content-Type': 'application/json', ...(token ? { Authorization: `Bearer ${token}` } : {}), ...extra }, ...(body ? { body: JSON.stringify(body) } : {}) });
  try {
    assert.throws(() => getUserIdFromHeaders({ 'x-user-id': userA }));
    assert.equal((await request('GET', '/specs', undefined, undefined, { 'x-user-id': userA })).status, 401);
    assert.equal((await request('GET', '/specs', 'forged')).status, 401);
    assert.equal((await request('GET', '/specs', jwt.sign({ sub: userA }))).status, 401);
    assert.equal((await request('GET', '/specs', jwt.sign({ sub: userA, sid: sessionB }))).status, 401);
    assert.equal((await request('GET', '/specs', jwt.sign({ sub: userA, sid: randomUUID() }))).status, 401);
    assert.equal((await request('GET', '/specs', jwt.sign({ sub: userA }, { expiresIn: -1 }))).status, 401);
    assert.equal((await request('GET', '/specs', jwt.sign({ sub: randomUUID() }))).status, 401);
    for (const type of Object.values(SpecType)) {
      const response = await request('POST', '/specs', a, { type });
      assert.equal(response.status, 201);
      const item = await response.json();
      assert.deepEqual(item.data, {});
      assert.equal(item.title, null);
      assert.equal(item.verification, 'unverified');
    }
    const response = await request('POST', '/specs', a, { type: 'certification', data: { name: '직접 등록', certificateNumber: '0001-A' } }, { 'x-user-id': userB });
    const item = await response.json();
    assert.equal(rows.find(row => row.id === item.id)?.userId, userA);
    assert.equal((await request('GET', `/specs/${item.id}`, b)).status, 404);
    assert.equal((await request('PATCH', `/specs/${item.id}`, b, { data: { name: '타인 변경' } })).status, 404);
    assert.equal((await request('DELETE', `/specs/${item.id}`, b)).status, 404);
    const updated = await (await request('PATCH', `/specs/${item.id}`, a, { data: { name: '', certificateNumber: null } })).json();
    assert.equal(updated.title, null);
    assert.deepEqual(updated.data, {});
    assert.equal((await request('PATCH', `/specs/${item.id}`, a, { type: 'project' })).status, 400);
    assert.equal((await request('POST', '/specs', a, { type: 'certification', userId: userB })).status, 400);
    assert.equal((await request('POST', '/specs', a, { type: 'certification', data: { acquiredOn: '2026-02-30' } })).status, 400);
    assert.equal((await request('GET', '/specs?limit=0', a)).status, 400);
    assert.equal((await request('GET', '/specs?type=other', a)).status, 400);
    const mine = await (await request('GET', '/specs', b)).json();
    assert.deepEqual(mine.items, []);
    assert.equal((await request('DELETE', `/specs/${item.id}`, a)).status, 200);
    assert.equal((await request('GET', `/specs/${item.id}`, a)).status, 404);
  } finally { await app.close(); }
});
