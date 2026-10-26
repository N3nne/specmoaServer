import { JOB_OCCUPATION_CODES, JobOccupation } from '../jobs/job-occupations';

export const CAREER_PREFERENCES_VERSION = 'career-preferences-v1';
export const CAREER_PREFERENCES_KEY = 'career';

export interface CareerPreferences {
  version: typeof CAREER_PREFERENCES_VERSION;
  status: 'unset' | 'set' | 'needs_review';
  desiredOccupations: JobOccupation[];
  updatedAt: string | null;
}

export function readCareerPreferences(preferences: unknown): CareerPreferences {
  const empty: CareerPreferences = { version: CAREER_PREFERENCES_VERSION, status: 'unset', desiredOccupations: [], updatedAt: null };
  if (!preferences || typeof preferences !== 'object' || Array.isArray(preferences)) return { ...empty, status: 'needs_review' };
  const stored: unknown = Reflect.get(preferences, CAREER_PREFERENCES_KEY);
  if (stored === undefined) return empty;
  if (!stored || typeof stored !== 'object' || Array.isArray(stored)) return { ...empty, status: 'needs_review' };
  const codes: unknown = Reflect.get(stored, 'desiredOccupations');
  const updatedAt: unknown = Reflect.get(stored, 'updatedAt');
  if (Reflect.get(stored, 'version') !== CAREER_PREFERENCES_VERSION || !Array.isArray(codes)
    || codes.length > JOB_OCCUPATION_CODES.length || new Set(codes).size !== codes.length
    || codes.some(code => !JOB_OCCUPATION_CODES.includes(code))
    || typeof updatedAt !== 'string' || !Number.isFinite(Date.parse(updatedAt))
    || new Date(updatedAt).toISOString() !== updatedAt) {
    return { ...empty, status: 'needs_review' };
  }
  return { version: CAREER_PREFERENCES_VERSION, status: codes.length ? 'set' : 'unset', desiredOccupations: [...codes], updatedAt };
}
