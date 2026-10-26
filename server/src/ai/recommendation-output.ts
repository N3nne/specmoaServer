import { RecommendationInput } from './demo-recommendation-data';

export type RecommendationReason = {
  specId: string;
  specField: string;
  specQuote: string;
  jobField: string;
  jobQuote: string;
  explanation: string;
};
export type Recommendation = {
  jobId: string;
  reasons: RecommendationReason[];
  cautions: string[];
};

const string = { type: 'string' };
export const RECOMMENDATION_SCHEMA = {
  type: 'object',
  additionalProperties: false,
  required: ['recommendations'],
  properties: {
    recommendations: {
      type: 'array',
      minItems: 0,
      maxItems: 3,
      items: {
        type: 'object',
        additionalProperties: false,
        required: ['jobId', 'reasons', 'cautions'],
        properties: {
          jobId: string,
          reasons: {
            type: 'array',
            minItems: 1,
            maxItems: 3,
            items: {
              type: 'object',
              additionalProperties: false,
              required: [
                'specId',
                'specField',
                'specQuote',
                'jobField',
                'jobQuote',
                'explanation',
              ],
              properties: {
                specId: string,
                specField: string,
                specQuote: string,
                jobField: string,
                jobQuote: string,
                explanation: string,
              },
            },
          },
          cautions: { type: 'array', minItems: 0, maxItems: 3, items: string },
        },
      },
    },
  },
};

function object(value: unknown, keys: string[]): Record<string, unknown> {
  if (
    !value ||
    typeof value !== 'object' ||
    Array.isArray(value) ||
    Object.keys(value).length !== keys.length ||
    keys.some((key) => !Object.prototype.hasOwnProperty.call(value, key))
  ) {
    throw new Error('Invalid recommendation structure.');
  }
  return value as Record<string, unknown>;
}

function text(value: unknown, max = 400): string {
  if (
    typeof value !== 'string' ||
    !value.trim() ||
    value.length > max ||
    /[\x00-\x08\x0b\x0c\x0e-\x1f]/.test(value)
  ) {
    throw new Error('Invalid recommendation text.');
  }
  // Percentages/ranks must not reappear through generated prose.
  if (
    /%|퍼센트|백분위|합격\s*(확률|가능성|보장)|pass\s*probability|guaranteed\s*(hire|pass)/i.test(
      value,
    )
  ) {
    throw new Error('Unsupported recommendation claim.');
  }
  return value;
}

function quote(fields: Record<string, string>, key: string, value: string) {
  if (
    !Object.prototype.hasOwnProperty.call(fields, key) ||
    value.trim().length < 2 ||
    !fields[key].includes(value)
  ) {
    throw new Error('Recommendation evidence does not exist.');
  }
}

export function validateRecommendations(
  raw: unknown,
  input: RecommendationInput,
): Recommendation[] {
  const root = object(raw, ['recommendations']);
  if (!Array.isArray(root.recommendations) || root.recommendations.length > 3)
    throw new Error('Invalid recommendation count.');
  const seen = new Set<string>();
  return root.recommendations.map((value) => {
    const item = object(value, ['jobId', 'reasons', 'cautions']);
    const jobId = text(item.jobId, 100);
    const job = input.jobs.find((candidate) => candidate.id === jobId);
    if (!job || seen.has(jobId))
      throw new Error('Unknown or duplicate recommendation job.');
    seen.add(jobId);
    if (
      !Array.isArray(item.reasons) ||
      item.reasons.length < 1 ||
      item.reasons.length > 3 ||
      !Array.isArray(item.cautions) ||
      item.cautions.length > 3
    )
      throw new Error('Invalid recommendation details.');
    const reasons = item.reasons.map((value) => {
      const reason = object(value, [
        'specId',
        'specField',
        'specQuote',
        'jobField',
        'jobQuote',
        'explanation',
      ]);
      const result: RecommendationReason = {
        specId: text(reason.specId, 100),
        specField: text(reason.specField, 100),
        specQuote: text(reason.specQuote),
        jobField: text(reason.jobField, 100),
        jobQuote: text(reason.jobQuote),
        explanation: text(reason.explanation),
      };
      const spec = input.specs.find(
        (candidate) => candidate.id === result.specId,
      );
      if (!spec) throw new Error('Unknown recommendation spec.');
      quote(spec.fields, result.specField, result.specQuote);
      quote(job.fields, result.jobField, result.jobQuote);
      return result;
    });
    return {
      jobId,
      reasons,
      cautions: item.cautions.map((value) => text(value)),
    };
  });
}
