import { BadRequestException } from '@nestjs/common';
import { isURL, isUUID } from 'class-validator';
import { SpecData, SpecType } from './spec-types';

type Rule = { kind: 'text' | 'number' | 'boolean' | 'date' | 'month' | 'url' | 'uuid' | 'tags' | 'reminders'; max?: number; options?: readonly (string | number)[]; positive?: boolean };
const text: Rule = { kind: 'text' };
const date: Rule = { kind: 'date' };
const month: Rule = { kind: 'month' };
const boolean: Rule = { kind: 'boolean' };
const url: Rule = { kind: 'url' };
const number: Rule = { kind: 'number' };
const tags: Rule = { kind: 'tags' };
const choice = (...options: (string | number)[]): Rule => ({ kind: 'text', options });
const limited = (max: number): Rule => ({ kind: 'text', max });

export const SPEC_FIELDS: Record<SpecType, Record<string, Rule>> = {
  certification: {
    certificationId: { kind: 'uuid' }, name: text, issuer: text, acquiredOn: date,
    result: text, grade: text, certificateNumber: text, lifetime: boolean, expiresOn: date,
    reminders: { kind: 'reminders', options: [60, 30, 7] }, keywords: { kind: 'tags', max: 5 },
  },
  language_score: {
    exam: choice('TOEIC', 'OPIc', '토익스피킹', 'JLPT', 'HSK', 'TEPS', 'TOEFL', '기타'),
    score: number, grade: text, testedOn: date, reminder: boolean, issuer: text, registrationNumber: text,
  },
  education_record: {
    academicStatus: choice('재학', '휴학', '졸업예정', '졸업'), degree: choice('학사', '전문학사', '석사', '박사'),
    school: text, major: text, hasAdditionalMajor: boolean, additionalMajor: text,
    additionalMajorType: choice('복수전공', '부전공', '연계전공'),
    gpaScale: { kind: 'number', options: [4.5, 4.3, 100] }, gpa: number, majorGpa: number,
  },
  award: {
    name: text, organizer: text, prize: choice('대상', '최우수상', '우수상', '장려상/입선', '특별상'),
    awardedOn: date, participation: choice('팀', '개인'), role: text, projectName: text,
    contribution: limited(500), relatedUrl: url, keywords: tags,
  },
  project: {
    name: text, projectType: choice('캡스톤/졸업작품', '사이드 프로젝트', '해커톤/공모전', '교내 수업/동아리'),
    startedMonth: month, endedMonth: month, ongoing: boolean, role: text,
    teamSize: choice('1인 개인', '2~4인 팀', '5인 이상'),
    situation: limited(300), task: limited(300), action: limited(500), result: limited(300),
    skills: tags, repositoryUrl: url, demoUrl: url,
  },
  work_experience: {
    company: text, employmentType: choice('인턴', '정규직', '계약직'), departmentRole: text,
    startedMonth: month, endedMonth: month, ongoing: boolean, summary: text,
    achievements: limited(500), troubleshooting: text,
  },
  external_activity: {
    name: text, organizer: text,
    activityType: choice('기업 서포터즈/기자단', '연합 동아리/학회', '봉사/사회공헌', '멘토링/교육봉사'),
    startedMonth: month, endedMonth: month, ongoing: boolean, role: text, description: limited(1000), awards: text,
  },
  training: {
    name: text, institution: text,
    trainingType: choice('K-Digital Training', '부트캠프 집중과정', '기업 주관 아카데미', '온라인 코스/직무교육'),
    hours: { kind: 'number', positive: true }, startedOn: date, completedOn: date,
    skills: { kind: 'tags', max: 10 }, summary: limited(300), projectName: text, projectRole: text, projectUrl: url,
  },
};

// Requiredness is independent of shape validation. All prototype inputs are optional.
export const REQUIRED_SPEC_FIELDS: Record<SpecType, readonly string[]> = {
  certification: [], language_score: [], education_record: [], award: [],
  project: [], work_experience: [], external_activity: [], training: [],
};

export function normalizeSpecData(type: SpecType, input: Record<string, unknown>): SpecData {
  const fields = SPEC_FIELDS[type];
  const data: SpecData = {};
  for (const [key, raw] of Object.entries(input)) {
    const rule = Object.prototype.hasOwnProperty.call(fields, key) ? fields[key] : undefined;
    if (!rule) throw new BadRequestException(`Unknown ${type} field: ${key}`);
    let value = typeof raw === 'string' ? raw.trim() : raw;
    if (value === null || value === undefined || value === '') continue;
    let valid = true;
    switch (rule.kind) {
      case 'text': valid = typeof value === 'string'; break;
      case 'number': valid = typeof value === 'number' && Number.isFinite(value) && (rule.positive ? value > 0 : value >= 0); break;
      case 'boolean': valid = typeof value === 'boolean'; break;
      case 'uuid': valid = typeof value === 'string' && isUUID(value); break;
      case 'date': valid = typeof value === 'string' && /^\d{4}-\d{2}-\d{2}$/.test(value) && Number.isFinite(Date.parse(value)) && new Date(value).toISOString().slice(0, 10) === value; break;
      case 'month': valid = typeof value === 'string' && /^\d{4}-(0[1-9]|1[0-2])$/.test(value); break;
      case 'url': valid = typeof value === 'string' && isURL(value, { protocols: ['http', 'https'], require_protocol: true }); break;
      case 'tags':
        valid = Array.isArray(value) && value.every(item => typeof item === 'string');
        if (valid) value = [...new Set((value as string[]).map(item => item.trim().replace(/^#+/, '').trim()).filter(Boolean))];
        break;
      case 'reminders': valid = Array.isArray(value) && value.every(item => typeof item === 'number' && rule.options?.includes(item));
        if (valid) value = [...new Set(value as number[])];
        break;
    }
    if (!valid || (rule.max !== undefined && (value as string | unknown[]).length > rule.max)
      || (rule.options && !['reminders'].includes(rule.kind) && !rule.options.includes(value as string | number))) {
      throw new BadRequestException(`Invalid value for ${key}`);
    }
    data[key] = value as SpecData[string];
  }
  for (const key of REQUIRED_SPEC_FIELDS[type]) {
    if (!(key in data) || Array.isArray(data[key]) && (data[key] as unknown[]).length === 0) throw new BadRequestException(`${key} is required`);
  }
  if (data.ongoing === true) delete data.endedMonth;
  if (data.lifetime === true) delete data.expiresOn;
  if (data.hasAdditionalMajor === false) {
    delete data.additionalMajor;
    delete data.additionalMajorType;
  }
  for (const [start, end] of [['startedMonth', 'endedMonth'], ['startedOn', 'completedOn'], ['acquiredOn', 'expiresOn']]) {
    if (data[start] && data[end] && data[start] > data[end]) throw new BadRequestException(`${end} must not precede ${start}`);
  }
  for (const key of ['gpa', 'majorGpa']) {
    if (typeof data[key] === 'number' && typeof data.gpaScale === 'number' && data[key] > data.gpaScale) {
      throw new BadRequestException(`${key} exceeds gpaScale`);
    }
  }
  const today = new Intl.DateTimeFormat('en-CA', { timeZone: 'Asia/Seoul', year: 'numeric', month: '2-digit', day: '2-digit' }).format(new Date());
  for (const key of ['acquiredOn', 'testedOn', 'awardedOn', 'completedOn']) {
    if (typeof data[key] === 'string' && data[key] > today) throw new BadRequestException(`${key} must not be in the future`);
  }
  if (type === SpecType.LANGUAGE_SCORE && typeof data.score === 'number' && data.exam === 'TOEIC' && data.score > 990) {
    throw new BadRequestException('TOEIC score must not exceed 990');
  }
  return data;
}

export function specTitle(type: SpecType, data: SpecData): string | null {
  const key = type === SpecType.LANGUAGE_SCORE ? 'exam' : type === SpecType.EDUCATION_RECORD ? 'school' : type === SpecType.WORK_EXPERIENCE ? 'company' : 'name';
  return typeof data[key] === 'string' ? data[key] : null;
}
