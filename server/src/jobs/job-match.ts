import { UserSpecEntity } from '../specs/entities/user-spec.entity';
import { SpecType } from '../specs/spec-types';
import { JobPostingEntity } from './entities/job-posting.entity';
import { EducationLevel, ExperienceLevel, JobRequirement } from './job.types';

export type JobMatchStatus = 'confirmed' | 'not_confirmed' | 'unknown' | 'not_required';
type ReasonCode = 'condition_not_required' | 'condition_missing' | 'evidence_missing' | 'evidence_incomplete'
  | 'minimum_met' | 'below_minimum' | 'certificate_validity_unconfirmed' | 'experience_policy_unspecified'
  | 'language_exam_ambiguous' | 'exact_keyword_match';
export type JobMatchCheck = {
  kind: string; condition: string; required: boolean; status: JobMatchStatus;
  reasonCode: ReasonCode; reason: string; evidenceSpecIds: string[];
};
type Condition = Pick<JobMatchCheck, 'kind' | 'condition' | 'required'>;
const normalize = (value: string) => value.normalize('NFKC').toLowerCase().replace(/\s+/g, '');
const degreeRanks = new Map<string, number>([
  ['high_school', 1], ['associate', 2], ['bachelor', 3], ['master', 4], ['doctor', 5],
  ['전문학사', 2], ['학사', 3], ['석사', 4], ['박사', 5],
]);
type Spec = Pick<UserSpecEntity, 'id' | 'type' | 'data'>;

function check(condition: Condition, status: JobMatchStatus, reasonCode: ReasonCode, reason: string, evidenceSpecIds: string[] = []): JobMatchCheck {
  return { ...condition, status, reasonCode, reason, evidenceSpecIds: [...new Set(evidenceSpecIds)] };
}

function calendarDate(value: unknown): value is string {
  return typeof value === 'string' && /^\d{4}-\d{2}-\d{2}$/.test(value) && Number.isFinite(Date.parse(value))
    && new Date(value).toISOString().slice(0, 10) === value;
}

function education(job: JobPostingEntity, specs: Spec[]): JobMatchCheck {
  const condition = { kind: 'education', condition: job.educationLevel ?? '학력 조건 정보 없음', required: true };
  if (job.educationLevel === EducationLevel.ANY) return check(condition, 'not_required', 'condition_not_required', '공고에서 학력 무관을 명시했습니다.');
  const minimum = job.educationLevel ? degreeRanks.get(job.educationLevel) : undefined;
  if (minimum === undefined) return check(condition, 'unknown', 'condition_missing', '비교할 수 있는 공고의 학력 기준이 없습니다.');
  const candidates = specs.filter(spec => spec.type === SpecType.EDUCATION_RECORD);
  if (!candidates.length) return check(condition, 'unknown', 'evidence_missing', '등록된 학력 정보가 없습니다.');
  const completed = candidates.filter(spec => spec.data.academicStatus === '졸업' &&
    typeof spec.data.degree === 'string' && degreeRanks.has(spec.data.degree));
  const matched = completed.filter(spec => degreeRanks.get(spec.data.degree as string)! >= minimum);
  if (matched.length) return check(condition, 'confirmed', 'minimum_met', '등록한 졸업 학위가 공고의 최소 학력 기준 이상입니다.', matched.map(spec => spec.id));
  if (completed.length !== candidates.length) {
    return check(condition, 'unknown', 'evidence_incomplete', '학위·졸업 상태가 없거나 재학·졸업예정 상태여서 최소 학력 충족을 확정할 수 없습니다.', completed.map(spec => spec.id));
  }
  return check(condition, 'not_confirmed', 'below_minimum', '등록한 졸업 학위가 공고의 최소 학력 기준보다 낮습니다. 미등록 학력이나 기업의 별도 인정 기준은 반영하지 않습니다.', completed.map(spec => spec.id));
}

function experience(job: JobPostingEntity, specs: Spec[], current: Date): JobMatchCheck {
  let condition: Condition = { kind: 'experience', condition: job.experienceLevel ?? '경력 조건 정보 없음', required: true };
  if (job.experienceLevel === ExperienceLevel.ANY) return check(condition, 'not_required', 'condition_not_required', '공고에서 경력 무관을 명시했습니다.');
  if (!job.experienceLevel) return check(condition, 'unknown', 'condition_missing', '공고의 경력 기준이 제공되지 않았습니다.');
  const minimum = job.minExperienceMonths;
  // An optional profile cannot establish a complete career history or employer-specific intern recognition.
  if (job.experienceLevel !== ExperienceLevel.EXPERIENCED || typeof minimum !== 'number' || !Number.isInteger(minimum) || minimum <= 0) {
    return check(condition, 'unknown', 'experience_policy_unspecified', '신입 인정 기준 또는 최소 경력 개월 수가 없어 등록 정보만으로 판단하지 않습니다.');
  }
  condition = { ...condition, condition: `경력 ${minimum}개월 이상 (정규직·계약직 등록 기간의 보수적 비교)` };
  const currentMonth = current.getUTCFullYear() * 12 + current.getUTCMonth();
  const monthIndex = (value: unknown) => typeof value === 'string' && /^\d{4}-(0[1-9]|1[0-2])$/.test(value)
    ? Number(value.slice(0, 4)) * 12 + Number(value.slice(5)) - 1 : null;
  const intervals: { start: number; end: number; id: string }[] = [];
  for (const spec of specs.filter(item => item.type === SpecType.WORK_EXPERIENCE)) {
    const start = monthIndex(spec.data.startedMonth);
    const end = spec.data.ongoing === true ? currentMonth : monthIndex(spec.data.endedMonth);
    // Intern recognition differs by employer; do not silently count it as required regular employment.
    if (typeof spec.data.employmentType !== 'string' || !['정규직', '계약직'].includes(spec.data.employmentType) ||
      start === null || end === null || start > end || start > currentMonth) continue;
    const enclosedEnd = Math.min(end, currentMonth);
    if (start + 1 < enclosedEnd) intervals.push({ start: start + 1, end: enclosedEnd, id: spec.id });
  }
  intervals.sort((a, b) => a.start - b.start || b.end - a.end || a.id.localeCompare(b.id));
  let months = 0, lastEnd = -1;
  const evidence: string[] = [];
  for (const interval of intervals) {
    // Both boundary months may be partial. Count only fully enclosed months, merging overlaps.
    const additional = Math.max(0, interval.end - Math.max(interval.start, lastEnd));
    if (additional > 0) evidence.push(interval.id);
    months += additional;
    lastEnd = Math.max(lastEnd, interval.end);
  }
  const explanation = `정규직·계약직에서 완전히 포함된 달을 중복 없이 합산한 기간은 ${months}개월입니다.`;
  if (months >= minimum) return check(condition, 'confirmed', 'minimum_met', `${explanation} 공고의 최소 기간 이상이며 기업의 실제 인정 경력과는 다를 수 있습니다.`, evidence);
  return check(condition, 'unknown', evidence.length ? 'evidence_incomplete' : 'evidence_missing', `${explanation} 미등록 경력이나 인턴 인정 여부를 알 수 없어 미충족으로 단정하지 않습니다.`, evidence);
}

function requirementCheck(rule: JobRequirement, specs: Spec[], today: string): JobMatchCheck {
  const base = { kind: rule.kind, condition: `${rule.name}${rule.minimumScore !== undefined ? ` ${rule.minimumScore}점 이상` : ''}`, required: rule.required };
  if (rule.kind === 'certification') {
    const candidates = specs.filter(spec => spec.type === SpecType.CERTIFICATION &&
      typeof spec.data.name === 'string' && normalize(spec.data.name) === normalize(rule.name));
    if (!candidates.length) return check(base, 'unknown', 'evidence_missing', '같은 명칭으로 등록한 자격증이 없습니다. 미등록을 미보유로 단정하지 않습니다.');
    const valid = candidates.filter(spec => calendarDate(spec.data.acquiredOn) && spec.data.acquiredOn <= today &&
      (spec.data.lifetime === true || calendarDate(spec.data.expiresOn) && spec.data.expiresOn >= today && spec.data.expiresOn >= spec.data.acquiredOn));
    if (valid.length) return check(base, 'confirmed', 'minimum_met', '명칭·취득일과 입력한 유효기간을 확인했습니다. 사용자 입력 기준이며 발급기관의 공식 인증은 아닙니다.', valid.map(spec => spec.id));
    return check(base, 'unknown', 'certificate_validity_unconfirmed', '명칭은 일치하지만 취득일·현재 유효기간을 확인할 수 없습니다. 유효기간 연장이나 기업의 별도 인정 여부는 추정하지 않습니다.', candidates.map(spec => spec.id));
  }
  if (rule.kind === 'language_score') {
    const condition = { ...base, condition: `${base.condition} (등록 점수만 비교, 유효기간 미판정)` };
    if (normalize(rule.name) === normalize('기타')) return check(condition, 'unknown', 'language_exam_ambiguous', '기타 항목만으로는 같은 시험인지 확인할 수 없습니다.');
    const minimum = rule.minimumScore;
    if (minimum === undefined || !Number.isFinite(minimum) || minimum < 0) {
      return check(condition, 'unknown', 'condition_missing', '공고에 비교 가능한 최소 점수가 없습니다. 등급을 점수로 임의 환산하지 않습니다.');
    }
    const candidates = specs.filter(spec => spec.type === SpecType.LANGUAGE_SCORE &&
      typeof spec.data.exam === 'string' && normalize(spec.data.exam) === normalize(rule.name));
    if (!candidates.length) return check(condition, 'unknown', 'evidence_missing', '같은 시험으로 등록한 어학 정보가 없습니다.');
    const comparable = candidates.filter(spec => typeof spec.data.score === 'number' && Number.isFinite(spec.data.score) && spec.data.score >= 0 &&
      (normalize(rule.name) !== 'toeic' || spec.data.score <= 990) &&
      (spec.data.testedOn === undefined || calendarDate(spec.data.testedOn) && spec.data.testedOn <= today));
    const matched = comparable.filter(spec => Number(spec.data.score) >= minimum);
    // This checks recorded score only. It does not infer exam validity periods or official verification.
    if (matched.length) return check(condition, 'confirmed', 'minimum_met', '등록한 점수가 공고의 최소 점수 이상입니다. 성적 유효기간과 공식 진위는 판단하지 않았습니다.', matched.map(spec => spec.id));
    if (comparable.length !== candidates.length) return check(condition, 'unknown', 'evidence_incomplete', '점수가 없거나 입력된 점수·응시일이 비교할 수 없는 값입니다. 등급을 임의 환산하거나 미래 성적을 사용하지 않습니다.', comparable.map(spec => spec.id));
    return check(condition, 'not_confirmed', 'below_minimum', '같은 시험의 등록 점수가 모두 최소 점수보다 낮습니다. 유효기간·미등록 성적·대체 인정 기준은 판단하지 않았습니다.', comparable.map(spec => spec.id));
  }
  const matched = specs.filter(spec => [spec.data.skills, spec.data.keywords].some(values =>
    Array.isArray(values) && values.some(value => typeof value === 'string' && normalize(value) === normalize(rule.name))));
  return matched.length
    ? check(base, 'confirmed', 'exact_keyword_match', '등록한 기술·키워드가 대소문자·공백 정규화 후 정확히 일치합니다. 실제 숙련도를 인증하지는 않습니다.', matched.map(spec => spec.id))
    : check(base, 'unknown', 'evidence_missing', '정확히 일치하는 등록 기술·키워드가 없습니다. 미등록을 기술 부재로 단정하지 않습니다.');
}

export function compareJob(job: JobPostingEntity, specs: Spec[], now = new Date()) {
  const current = new Date(now.getTime() + 9 * 60 * 60 * 1000);
  const today = current.toISOString().slice(0, 10);
  const checks = [education(job, specs), experience(job, specs, current),
    ...(job.requirements ?? []).map(rule => requirementCheck(rule, specs, today))];
  return {
    method: 'rules-v2',
    comparedAt: now.toISOString(),
    notice: '등록한 정보와 공고 조건을 비교한 참고 결과입니다. 공식 인증·합격 확률·지원 가능 여부를 보장하지 않습니다. 미입력은 미충족으로 처리하지 않습니다.',
    detailedRequirementsAvailable: job.requirements !== null,
    required: summarize(checks.filter(check => check.required)),
    preferred: summarize(checks.filter(check => !check.required)),
    checks,
  };
}

function summarize(checks: JobMatchCheck[]) {
  return Object.fromEntries((['confirmed', 'not_confirmed', 'unknown', 'not_required'] as const)
    .map(status => [status, checks.filter(check => check.status === status).length]));
}
