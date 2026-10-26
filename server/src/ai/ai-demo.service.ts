import {
  HttpException,
  HttpStatus,
  Inject,
  Injectable,
  Optional,
  ServiceUnavailableException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import {
  DemoProfile,
  DEMO_PROFILE_DETAILS,
  demoRecommendationInput,
} from './demo-recommendation-data';
import {
  DEFAULT_GEMINI_MODEL,
  GEMINI_MODELS,
  RecommendationProvider,
} from './gemini.client';

export const RECOMMENDATION_PROVIDER = Symbol('RECOMMENDATION_PROVIDER');
export const AI_CLOCK = Symbol('AI_CLOCK');
export const AI_DEMO_NOTICE =
  '가상 스펙과 가상 공고만 사용한 AI 시연입니다. 실제 사용자 분석·합격 확률·공식 인증을 제공하지 않습니다. AI의 설명은 틀릴 수 있습니다.';

@Injectable()
export class AiDemoService {
  private day = '';
  private attempts = 0;
  private readonly users = new Map<string, number>();
  private readonly cache = new Map<
    string,
    {
      expiresAt: number;
      result: Awaited<ReturnType<AiDemoService['generate']>>;
    }
  >();
  private readonly pending = new Map<
    string,
    ReturnType<AiDemoService['generate']>
  >();
  private cooldownUntil = 0;

  constructor(
    private readonly config: ConfigService,
    @Inject(RECOMMENDATION_PROVIDER)
    private readonly provider: RecommendationProvider,
    @Optional()
    @Inject(AI_CLOCK)
    private readonly clock: () => number = Date.now,
  ) {}

  availability() {
    return {
      enabled: this.enabled(),
      synthetic: true,
      profileId: DemoProfile.BACKEND,
      ...DEMO_PROFILE_DETAILS[DemoProfile.BACKEND],
      notice: AI_DEMO_NOTICE,
    };
  }

  private enabled() {
    return (
      this.config.get('NODE_ENV') !== 'production' &&
      this.config.get('AI_DEMO_ENABLED') === 'true' &&
      Boolean(this.config.get<string>('GEMINI_API_KEY', '').trim()) &&
      GEMINI_MODELS.includes(
        this.config.get<string>('GEMINI_MODEL', DEFAULT_GEMINI_MODEL),
      )
    );
  }

  async recommend(
    profile: DemoProfile,
    callerId: string,
    now = new Date(this.clock()),
  ) {
    // Key presence alone must never enable an external AI route or a production rollout.
    if (
      this.config.get('NODE_ENV') === 'production' ||
      this.config.get('AI_DEMO_ENABLED') !== 'true'
    ) {
      throw new ServiceUnavailableException(
        'AI 가상 데이터 테스트가 활성화되지 않았습니다.',
      );
    }
    const apiKey = this.config.get<string>('GEMINI_API_KEY', '').trim();
    const model = this.config.get<string>('GEMINI_MODEL', DEFAULT_GEMINI_MODEL);
    if (!apiKey || !GEMINI_MODELS.includes(model))
      throw new ServiceUnavailableException('Gemini 서버 설정을 확인해주세요.');
    const day = new Date(now.getTime() + 9 * 60 * 60 * 1000)
      .toISOString()
      .slice(0, 10);
    if (this.day !== day) {
      this.day = day;
      this.attempts = 0;
      this.users.clear();
      this.cache.clear();
    }
    const key = `${day}:${profile}:${model}`;
    const cached = this.cache.get(key);
    if (cached && cached.expiresAt > now.getTime())
      return structuredClone({ ...cached.result, cached: true });
    const pending = this.pending.get(key);
    if (pending) return structuredClone(await pending);
    // Local prototype limits, not Google's project quota. Restarts reset these counters.
    if (
      now.getTime() < this.cooldownUntil ||
      this.attempts >= 10 ||
      (this.users.get(callerId) ?? 0) >= 3 ||
      this.pending.size >= 1
    ) {
      throw new HttpException(
        'AI 테스트 호출 제한에 도달했습니다. 저장된 결과를 사용하거나 나중에 다시 시도해주세요.',
        HttpStatus.TOO_MANY_REQUESTS,
      );
    }
    this.attempts++;
    this.users.set(callerId, (this.users.get(callerId) ?? 0) + 1);
    const request = this.generate(profile, { apiKey, model }, now);
    this.pending.set(key, request);
    try {
      const result = await request;
      this.cache.set(key, { expiresAt: this.clock() + 15 * 60_000, result });
      return structuredClone(result);
    } catch (error) {
      if (error instanceof HttpException && error.getStatus() === 429)
        this.cooldownUntil = this.clock() + 60_000;
      throw error;
    } finally {
      this.pending.delete(key);
    }
  }

  private async generate(
    profile: DemoProfile,
    options: { apiKey: string; model: string },
    now: Date,
  ) {
    const input = await demoRecommendationInput(profile, now);
    const generated = await this.provider.recommend(input, options);
    // Generic degree/language overlap alone is not a meaningful job recommendation.
    const recommendations = generated.filter((item) =>
      item.reasons.some(
        (reason) =>
          ['skills', 'keywords', 'description'].includes(reason.specField) &&
          input.specs.some(
            (spec) =>
              spec.id === reason.specId &&
              [
                'project',
                'work_experience',
                'external_activity',
                'training',
              ].includes(spec.fields.type),
          ),
      ),
    );
    return {
      method: 'gemini-demo-v1',
      synthetic: true,
      profileId: profile,
      ...DEMO_PROFILE_DETAILS[profile],
      model: options.model,
      generatedAt: new Date(this.clock()).toISOString(),
      cached: false,
      notice: AI_DEMO_NOTICE,
      candidateCount: input.jobs.length,
      items: recommendations.map((item, index) => {
        const job = input.jobs.find((job) => job.id === item.jobId)!;
        return {
          rank: index + 1,
          jobExternalId: job.id,
          companyName: job.companyName,
          title: job.fields.title,
          ...job.metadata,
          reasons: item.reasons,
          cautions: item.cautions,
          comparison: job.comparison,
        };
      }),
    };
  }
}
