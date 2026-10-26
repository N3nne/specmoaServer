import 'reflect-metadata';
import * as assert from 'node:assert/strict';
import { test } from 'node:test';
import { randomUUID } from 'node:crypto';
import {
  HttpException,
  NotFoundException,
  ValidationPipe,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { APP_GUARD } from '@nestjs/core';
import { JwtService } from '@nestjs/jwt';
import { Test } from '@nestjs/testing';
import { AuthGuard } from '../src/auth/auth.guard';
import { AuthSessionsService } from '../src/auth/auth-sessions.service';
import { UsersService } from '../src/users/users.service';
import { AiDemoController } from '../src/ai/ai-demo.controller';
import { AiModule } from '../src/ai/ai.module';
import {
  AiDemoService,
  RECOMMENDATION_PROVIDER,
} from '../src/ai/ai-demo.service';
import {
  DemoProfile,
  RecommendationInput,
  demoRecommendationInput,
} from '../src/ai/demo-recommendation-data';
import {
  DEFAULT_GEMINI_MODEL,
  GeminiClient,
  RecommendationProvider,
} from '../src/ai/gemini.client';
import {
  Recommendation,
  validateRecommendations,
} from '../src/ai/recommendation-output';

const now = new Date('2026-10-26T00:00:00+09:00');
const secret = 'test-only-never-a-real-api-key';
const config = (values: Record<string, string | undefined> = {}) =>
  new ConfigService({
    NODE_ENV: 'test',
    AI_DEMO_ENABLED: 'true',
    GEMINI_API_KEY: secret,
    ...values,
  });
const valid = (input: RecommendationInput): Recommendation[] => [
  {
    jobId: input.jobs[0].id,
    reasons: [
      {
        specId: input.specs[1].id,
        specField: 'skills',
        specQuote: 'TypeScript',
        jobField: 'requirements',
        jobQuote: 'TypeScript',
        explanation: '등록된 기술과 공고에 명시된 기술이 관련되어 있습니다.',
      },
    ],
    cautions: ['기업의 실제 인정 기준은 별도 확인이 필요합니다.'],
  },
];
const envelope = (input: RecommendationInput, finishReason = 'STOP') => ({
  candidates: [
    {
      finishReason,
      content: {
        parts: [{ text: JSON.stringify({ recommendations: valid(input) }) }],
      },
    },
  ],
});
const httpError = (status: number) => (error: unknown) =>
  error instanceof HttpException &&
  error.getStatus() === status &&
  !error.message.includes(secret);

test('AI module has no repositories, user-data services or database imports', () => {
  assert.deepEqual(Reflect.getMetadata('imports', AiModule) ?? [], []);
});

test('three fixed synthetic profiles use only open fictional candidate jobs with no personal fields', async () => {
  for (const profile of Object.values(DemoProfile)) {
    const input = await demoRecommendationInput(profile, now);
    assert.equal(input.jobs.length, 9);
    assert.ok(
      input.specs.every((spec) => spec.id.startsWith(`demo-${profile}-`)),
    );
    assert.ok(
      input.jobs.every(
        (job) =>
          job.fields.title.startsWith('[가상 공고]') &&
          job.companyName.startsWith('스펙모아 가상기업'),
      ),
    );
    assert.doesNotMatch(
      JSON.stringify(input),
      /userId|email|certificateNumber|phone|apiKey/,
    );
    assert.equal(
      input.jobs.some((job) => job.id === 'specmoa-demo-v1-037'),
      false,
    );
  }
});

test('output accepts real supplied evidence or an empty result, not forged jobs/specs/quotes/properties/percentages', async () => {
  const input = await demoRecommendationInput(DemoProfile.BACKEND, now);
  assert.deepEqual(
    validateRecommendations({ recommendations: valid(input) }, input),
    valid(input),
  );
  assert.deepEqual(validateRecommendations({ recommendations: [] }, input), []);
  const mutations: ((items: Recommendation[]) => unknown)[] = [
    (items) => {
      items[0].jobId = 'unknown';
    },
    (items) => {
      items.push(structuredClone(items[0]));
    },
    (items) => {
      items[0].reasons[0].specId = 'another-user-spec';
    },
    (items) => {
      items[0].reasons[0].specField = 'toString';
    },
    (items) => {
      items[0].reasons[0].jobField = '__proto__';
    },
    (items) => {
      items[0].reasons[0].specQuote = 'Rust';
    },
    (items) => {
      items[0].reasons[0].jobQuote = 'Kubernetes';
    },
    (items) => {
      items[0].reasons[0].jobQuote = 'T';
    },
    (items) => {
      items[0].reasons[0].explanation = '매칭률 96%입니다.';
    },
    (items) => {
      items[0].cautions = ['합격 확률이 높습니다.'];
    },
    (items) => {
      items[0].reasons = [];
    },
    (items) => {
      items[0].cautions = ['x'.repeat(401)];
    },
    (items) => {
      Object.assign(items[0], { probability: 0.9 });
    },
  ];
  for (const mutate of mutations) {
    const items = valid(input);
    mutate(items);
    assert.throws(() =>
      validateRecommendations({ recommendations: items }, input),
    );
  }
  assert.throws(() =>
    validateRecommendations({ recommendations: [], extra: 'field' }, input),
  );
  assert.throws(() =>
    validateRecommendations(
      { recommendations: new Array(4).fill(valid(input)[0]) },
      input,
    ),
  );
});

test('Gemini transport sends bounded JSON to a fixed Google endpoint, keeps key in header, verifies output', async () => {
  const input = await demoRecommendationInput(DemoProfile.BACKEND, now);
  let calls = 0;
  const client = new GeminiClient(async (url, options) => {
    calls++;
    assert.equal(
      url,
      `https://generativelanguage.googleapis.com/v1beta/models/${DEFAULT_GEMINI_MODEL}:generateContent`,
    );
    assert.equal(
      (options?.headers as Record<string, string>)['x-goog-api-key'],
      secret,
    );
    assert.equal(options?.redirect, 'error');
    assert.ok(options?.signal);
    const body = JSON.parse(String(options?.body));
    const sent = JSON.parse(body.contents[0].parts[0].text);
    assert.deepEqual(sent.specs, input.specs);
    assert.deepEqual(
      sent.jobs.map((job: { id: string }) => job.id),
      input.jobs.map((job) => job.id),
    );
    assert.deepEqual(sent.jobs[0].fields, input.jobs[0].fields);
    assert.deepEqual(
      sent.jobs[0].checks,
      input.jobs[0].comparison.checks.map(
        ({ condition, required, status }) => ({ condition, required, status }),
      ),
    );
    assert.equal(sent.jobs[0].comparison, undefined);
    assert.equal(body.generationConfig.maxOutputTokens, 4096);
    assert.equal(body.generationConfig.responseMimeType, 'application/json');
    assert.deepEqual(body.generationConfig.thinkingConfig, {
      thinkingLevel: 'MINIMAL',
    });
    assert.equal(body.tools, undefined);
    assert.doesNotMatch(JSON.stringify(body), new RegExp(secret));
    return Response.json(envelope(input));
  });
  assert.deepEqual(
    await client.recommend(input, {
      apiKey: secret,
      model: DEFAULT_GEMINI_MODEL,
    }),
    valid(input),
  );
  assert.equal(calls, 1);
});

test('normal text with thought signatures is accepted without exposing signature or reasoning', async () => {
  const input = await demoRecommendationInput(DemoProfile.BACKEND, now);
  for (const parts of [
    [
      {
        text: JSON.stringify({ recommendations: valid(input) }),
        thoughtSignature: 'mock-signature',
      },
    ],
    [
      { text: 'private reasoning', thought: true },
      { text: JSON.stringify({ recommendations: valid(input) }) },
      { thoughtSignature: 'mock-signature' },
    ],
  ]) {
    const client = new GeminiClient(async () =>
      Response.json({
        candidates: [{ finishReason: 'STOP', content: { parts } }],
      }),
    );
    const result = await client.recommend(input, {
      apiKey: secret,
      model: DEFAULT_GEMINI_MODEL,
    });
    assert.deepEqual(result, valid(input));
    assert.doesNotMatch(
      JSON.stringify(result),
      /mock-signature|private reasoning/,
    );
  }
});

test('3.8 alternative uses its supported LOW thinking level, without automatic fallback', async () => {
  const input = await demoRecommendationInput(DemoProfile.BACKEND, now);
  const client = new GeminiClient(async (_url, options) => {
    assert.equal(
      JSON.parse(String(options?.body)).generationConfig.thinkingConfig
        .thinkingLevel,
      'LOW',
    );
    return Response.json(envelope(input));
  });
  assert.deepEqual(
    await client.recommend(input, {
      apiKey: secret,
      model: 'gemini-3.8-flash',
    }),
    valid(input),
  );
});

test('Gemini errors never expose upstream bodies/secrets, retry automatically or switch models', async () => {
  const input = await demoRecommendationInput(DemoProfile.BACKEND, now);
  for (const [upstream, status] of [
    [400, 502],
    [401, 503],
    [403, 503],
    [404, 503],
    [429, 429],
    [500, 502],
    [503, 503],
  ]) {
    let calls = 0;
    const client = new GeminiClient(async () => {
      calls++;
      return new Response(secret, { status: upstream });
    });
    await assert.rejects(
      () =>
        client.recommend(input, {
          apiKey: secret,
          model: DEFAULT_GEMINI_MODEL,
        }),
      httpError(status),
    );
    assert.equal(calls, 1);
  }
  const timeout = new GeminiClient(async () => {
    throw new DOMException(secret, 'TimeoutError');
  });
  await assert.rejects(
    () =>
      timeout.recommend(input, { apiKey: secret, model: DEFAULT_GEMINI_MODEL }),
    httpError(503),
  );
  const network = new GeminiClient(async () => {
    throw new Error(secret);
  });
  await assert.rejects(
    () =>
      network.recommend(input, { apiKey: secret, model: DEFAULT_GEMINI_MODEL }),
    httpError(502),
  );
});

test('blocked, partial, malformed, extra candidate, thought and oversized Gemini replies are rejected', async () => {
  const input = await demoRecommendationInput(DemoProfile.BACKEND, now);
  const good = envelope(input);
  const variants = [
    envelope(input, 'MAX_TOKENS'),
    envelope(input, 'SAFETY'),
    { ...good, promptFeedback: { blockReason: 'SAFETY' } },
    { candidates: [good.candidates[0], good.candidates[0]] },
    { candidates: [] },
    {},
    {
      candidates: [
        { finishReason: 'STOP', content: { parts: [{ text: '{' }] } },
      ],
    },
    {
      candidates: [
        {
          finishReason: 'STOP',
          content: { parts: [{ text: '{}', thought: true }] },
        },
      ],
    },
    {
      candidates: [
        {
          finishReason: 'STOP',
          content: { parts: [{ functionCall: { name: 'oops' } }] },
        },
      ],
    },
    { huge: 'x'.repeat(70_000) },
  ];
  for (const body of variants) {
    const client = new GeminiClient(async () => Response.json(body));
    await assert.rejects(
      () =>
        client.recommend(input, {
          apiKey: secret,
          model: DEFAULT_GEMINI_MODEL,
        }),
      httpError(502),
    );
  }
});

test('invalid model/key or oversized prompt makes no upstream request', async () => {
  const input = await demoRecommendationInput(DemoProfile.BACKEND, now);
  let calls = 0;
  const client = new GeminiClient(async () => {
    calls++;
    return Response.json({});
  });
  await assert.rejects(
    () => client.recommend(input, { apiKey: '', model: DEFAULT_GEMINI_MODEL }),
    httpError(503),
  );
  await assert.rejects(
    () => client.recommend(input, { apiKey: secret, model: '../paid-model' }),
    httpError(503),
  );
  input.specs[0].fields.description = 'x'.repeat(33_000);
  await assert.rejects(
    () =>
      client.recommend(input, { apiKey: secret, model: DEFAULT_GEMINI_MODEL }),
    httpError(502),
  );
  assert.equal(calls, 0);
});

test('HTTP demo requires explicit enable and stays disabled in production even with a key', async () => {
  let calls = 0;
  const provider: RecommendationProvider = {
    recommend: async () => {
      calls++;
      return [];
    },
  };
  for (const values of [
    { AI_DEMO_ENABLED: 'false' },
    { AI_DEMO_ENABLED: '' },
    { NODE_ENV: 'production' },
    { GEMINI_API_KEY: '' },
    { GEMINI_MODEL: 'unsupported' },
  ]) {
    const service = new AiDemoService(config(values), provider);
    await assert.rejects(
      () => service.recommend(DemoProfile.BACKEND, 'a', now),
      httpError(503),
    );
  }
  assert.equal(calls, 0);
});

test('same-profile requests coalesce; cached copies cannot be mutated by callers', async () => {
  let release!: (items: Recommendation[]) => void;
  let calls = 0;
  const service = new AiDemoService(config(), {
    recommend: () => {
      calls++;
      return new Promise<Recommendation[]>((resolve) => {
        release = resolve;
      });
    },
  });
  const first = service.recommend(DemoProfile.BACKEND, 'a', now);
  const second = service.recommend(DemoProfile.BACKEND, 'b', now);
  await new Promise((resolve) => setImmediate(resolve));
  assert.equal(calls, 1);
  release(valid(await demoRecommendationInput(DemoProfile.BACKEND, now)));
  const a = await first,
    b = await second;
  a.items[0].title = 'changed';
  assert.notEqual(b.items[0].title, 'changed');
  const cached = await service.recommend(DemoProfile.BACKEND, 'b', now);
  assert.equal(cached.cached, true);
  assert.notEqual(cached.items[0].title, 'changed');
  assert.equal(calls, 1);
  assert.equal(cached.items[0].comparison.method, 'rules-v2');
  assert.equal(cached.synthetic, true);
  assert.equal('score' in cached.items[0], false);
});

test('generic language-only overlap cannot create unrelated job recommendations', async () => {
  const service = new AiDemoService(config(), {
    recommend: async (input) => [
      valid(input)[0],
      {
        jobId: input.jobs[3].id,
        reasons: [
          {
            specId: 'demo-backend-language',
            specField: 'score',
            specQuote: '750',
            jobField: 'requirements',
            jobQuote: 'TOEIC 700점 이상',
            explanation: '어학 점수가 일치합니다.',
          },
        ],
        cautions: [],
      },
    ],
  });
  const result = await service.recommend(DemoProfile.BACKEND, 'a', now);
  assert.equal(result.items.length, 1);
  assert.equal(result.items[0].jobExternalId, 'specmoa-demo-v1-001');
  assert.equal(result.items[0].rank, 1);
});

test('different profiles cannot open concurrent upstream calls; failed calls count toward daily caps', async () => {
  let release!: (items: Recommendation[]) => void;
  const pending = new AiDemoService(config(), {
    recommend: () =>
      new Promise((resolve) => {
        release = resolve;
      }),
  });
  const first = pending.recommend(DemoProfile.BACKEND, 'a', now);
  await assert.rejects(
    () => pending.recommend(DemoProfile.MOBILE, 'b', now),
    httpError(429),
  );
  await new Promise((resolve) => setImmediate(resolve));
  release([]);
  await first;
  let calls = 0;
  const limited = new AiDemoService(config(), {
    recommend: async () => {
      calls++;
      throw new HttpException('failed', 502);
    },
  });
  for (let i = 0; i < 3; i++)
    await assert.rejects(
      () => limited.recommend(DemoProfile.BACKEND, 'a', now),
      httpError(502),
    );
  await assert.rejects(
    () => limited.recommend(DemoProfile.BACKEND, 'a', now),
    httpError(429),
  );
  for (let i = 0; i < 7; i++)
    await assert.rejects(
      () => limited.recommend(DemoProfile.BACKEND, `b${i}`, now),
      httpError(502),
    );
  await assert.rejects(
    () => limited.recommend(DemoProfile.BACKEND, 'fresh', now),
    httpError(429),
  );
  assert.equal(calls, 10);
  const tomorrow = new Date(now.getTime() + 86_400_000);
  await assert.rejects(
    () => limited.recommend(DemoProfile.BACKEND, 'a', tomorrow),
    httpError(502),
  );
  assert.equal(calls, 11);
});

test('cache expires after 15 minutes and upstream 429 applies a shared cooldown without retry', async () => {
  let calls = 0;
  const service = new AiDemoService(
    config(),
    {
      recommend: async () => {
        calls++;
        return [];
      },
    },
    () => now.getTime(),
  );
  await service.recommend(DemoProfile.BACKEND, 'a', now);
  await service.recommend(
    DemoProfile.BACKEND,
    'a',
    new Date(now.getTime() + 14 * 60_000),
  );
  assert.equal(calls, 1);
  await service.recommend(
    DemoProfile.BACKEND,
    'a',
    new Date(now.getTime() + 15 * 60_000),
  );
  assert.equal(calls, 2);
  const limited = new AiDemoService(config(), {
    recommend: async () => {
      throw new HttpException('quota', 429);
    },
  });
  await assert.rejects(
    () => limited.recommend(DemoProfile.BACKEND, 'a', now),
    httpError(429),
  );
  await assert.rejects(
    () =>
      limited.recommend(
        DemoProfile.MOBILE,
        'b',
        new Date(now.getTime() + 59_000),
      ),
    httpError(429),
  );
});

test('slow responses start cache and 429 cooldown at completion, not request start', async () => {
  let wall = now.getTime();
  let calls = 0;
  const service = new AiDemoService(
    config(),
    {
      recommend: async () => {
        calls++;
        wall += 40_000;
        return [];
      },
    },
    () => wall,
  );
  const result = await service.recommend(DemoProfile.BACKEND, 'a');
  assert.equal(result.generatedAt, new Date(wall).toISOString());
  const completed = wall;
  wall = completed + 15 * 60_000 - 1;
  await service.recommend(DemoProfile.BACKEND, 'a');
  assert.equal(calls, 1);
  wall++;
  await service.recommend(DemoProfile.BACKEND, 'a');
  assert.equal(calls, 2);

  calls = 0;
  const limited = new AiDemoService(
    config(),
    {
      recommend: async () => {
        calls++;
        wall += 40_000;
        throw new HttpException('quota', 429);
      },
    },
    () => wall,
  );
  await assert.rejects(
    () => limited.recommend(DemoProfile.BACKEND, 'a'),
    httpError(429),
  );
  const failed = wall;
  wall = failed + 59_999;
  await assert.rejects(
    () => limited.recommend(DemoProfile.MOBILE, 'b'),
    httpError(429),
  );
  assert.equal(calls, 1);
  wall++;
  await assert.rejects(
    () => limited.recommend(DemoProfile.MOBILE, 'b'),
    httpError(429),
  );
  assert.equal(calls, 2);
});

test('authenticated demo endpoint only accepts a fixed profile enum, never user specs, ids, prompts or queries', async () => {
  const userId = randomUUID(),
    sessionId = randomUUID();
  const jwt = new JwtService({ secret: 'test-only-auth-secret' });
  let calls = 0;
  const module = await Test.createTestingModule({
    controllers: [AiDemoController],
    providers: [
      AiDemoService,
      { provide: ConfigService, useValue: config() },
      {
        provide: RECOMMENDATION_PROVIDER,
        useValue: {
          recommend: async (input: RecommendationInput) => {
            calls++;
            return valid(input);
          },
        },
      },
      { provide: APP_GUARD, useClass: AuthGuard },
      { provide: JwtService, useValue: jwt },
      {
        provide: AuthSessionsService,
        useValue: {
          isActive: async (sid: string, sub: string) =>
            sid === sessionId && sub === userId,
        },
      },
      {
        provide: UsersService,
        useValue: {
          findById: async (id: string) => {
            if (id !== userId) throw new NotFoundException();
            return { id };
          },
        },
      },
    ],
  }).compile();
  const app = module.createNestApplication({ logger: false });
  app.useGlobalPipes(
    new ValidationPipe({
      transform: true,
      whitelist: true,
      forbidNonWhitelisted: true,
    }),
  );
  await app.listen(0, '127.0.0.1');
  const base = await app.getUrl();
  const token = await jwt.signAsync({ sub: userId, sid: sessionId });
  const request = (
    body: unknown,
    authorization = `Bearer ${token}`,
    query = '',
  ) =>
    fetch(`${base}/ai/demo/recommendations${query}`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: authorization,
      },
      body: JSON.stringify(body),
    });
  try {
    assert.equal((await fetch(`${base}/ai/demo/status`)).status, 401);
    const status = await (
      await fetch(`${base}/ai/demo/status`, {
        headers: { Authorization: `Bearer ${token}` },
      })
    ).json();
    assert.equal(status.enabled, true);
    assert.equal(status.synthetic, true);
    assert.equal(status.profileId, 'backend');
    assert.doesNotMatch(JSON.stringify(status), new RegExp(secret));
    assert.equal((await request({ profile: 'backend' }, '')).status, 401);
    assert.equal(
      (await request({ profile: 'backend' }, 'Bearer forged')).status,
      401,
    );
    for (const body of [
      {},
      { profile: 'user' },
      { profile: ['backend'] },
      { profile: 'backend', userId },
      { profile: 'backend', specs: [] },
      { profile: 'backend', prompt: 'private text' },
    ]) {
      assert.equal((await request(body)).status, 400);
    }
    assert.equal(
      (
        await request(
          { profile: 'backend' },
          `Bearer ${token}`,
          '?userId=other',
        )
      ).status,
      400,
    );
    assert.equal(calls, 0);
    const response = await request({ profile: 'backend' });
    assert.equal(response.status, 200);
    assert.equal(response.headers.get('cache-control'), 'no-store');
    const body = await response.json();
    assert.equal(body.synthetic, true);
    assert.equal(body.profileId, 'backend');
    assert.equal(body.items.length, 1);
    assert.equal(calls, 1);
    assert.doesNotMatch(
      JSON.stringify(body),
      new RegExp(`${secret}|${userId}|${token}`),
    );
  } finally {
    await app.close();
  }
});
