import { UserSpecEntity } from '../specs/entities/user-spec.entity';
import { normalizeSpecData } from '../specs/spec-field-policy';
import { SpecData, SpecType } from '../specs/spec-types';

// An allowlist prevents new registration fields from silently entering analysis data.
const ANALYSIS_FIELDS: Record<SpecType, readonly string[]> = {
  certification: ['name', 'issuer', 'acquiredOn', 'result', 'grade', 'lifetime', 'expiresOn', 'keywords'],
  language_score: ['exam', 'score', 'grade', 'testedOn', 'issuer'],
  education_record: ['academicStatus', 'degree', 'school', 'major', 'hasAdditionalMajor', 'additionalMajor', 'additionalMajorType', 'gpaScale', 'gpa', 'majorGpa'],
  award: ['name', 'organizer', 'prize', 'awardedOn', 'participation', 'role', 'projectName', 'contribution', 'keywords'],
  project: ['name', 'projectType', 'startedMonth', 'endedMonth', 'ongoing', 'role', 'teamSize', 'situation', 'task', 'action', 'result', 'skills'],
  work_experience: ['company', 'employmentType', 'departmentRole', 'startedMonth', 'endedMonth', 'ongoing', 'summary', 'achievements', 'troubleshooting'],
  external_activity: ['name', 'organizer', 'activityType', 'startedMonth', 'endedMonth', 'ongoing', 'role', 'description', 'awards'],
  training: ['name', 'institution', 'trainingType', 'hours', 'startedOn', 'completedOn', 'skills', 'summary', 'projectName', 'projectRole'],
};

const CONTEXT_GROUPS: Record<SpecType, readonly (readonly string[])[]> = {
  certification: [['name']],
  language_score: [['exam'], ['score', 'grade']],
  education_record: [['degree'], ['academicStatus']],
  award: [['name'], ['prize', 'contribution', 'role']],
  project: [['name'], ['skills', 'role', 'situation', 'task', 'action', 'result']],
  work_experience: [['company'], ['departmentRole', 'summary', 'achievements', 'troubleshooting']],
  external_activity: [['name'], ['role', 'description']],
  training: [['name'], ['skills', 'summary']],
};

type AnalysisIssue = { field: string | null; code: 'invalid_value' | 'inconsistent_range' | 'missing_context' | 'invalid_record' | 'unsupported_type' };
export interface SpecAnalysisRecord {
  specId: string;
  type: SpecType;
  updatedAt: string;
  verification: 'unverified';
  status: 'empty' | 'partial' | 'available' | 'unsupported';
  facts: { field: string; path: string; value: SpecData[string] }[];
  missingFields: string[];
  missingContext: string[][];
  issues: AnalysisIssue[];
}

function present(value: unknown) {
  return value !== undefined && value !== null && value !== '' && (!Array.isArray(value) || value.length > 0);
}

export function prepareSpecAnalysis(spec: Pick<UserSpecEntity, 'id' | 'type' | 'data' | 'updatedAt'>): SpecAnalysisRecord {
  const record: SpecAnalysisRecord = {
    specId: spec.id, type: spec.type, updatedAt: spec.updatedAt.toISOString(), verification: 'unverified',
    status: 'empty', facts: [], missingFields: [], missingContext: [], issues: [],
  };
  const fields = Object.prototype.hasOwnProperty.call(ANALYSIS_FIELDS, spec.type) ? ANALYSIS_FIELDS[spec.type] : undefined;
  if (!fields) return { ...record, status: 'unsupported', issues: [{ field: null, code: 'unsupported_type' }] };
  const raw: unknown = spec.data;
  if (!raw || typeof raw !== 'object' || Array.isArray(raw)) {
    return { ...record, status: 'partial', missingFields: [...fields], missingContext: CONTEXT_GROUPS[spec.type].map(group => [...group]), issues: [{ field: null, code: 'invalid_record' }] };
  }
  const data: SpecData = {};
  for (const field of fields) {
    // The registration validator is reused without turning optional fields into required fields.
    try { Object.assign(data, normalizeSpecData(spec.type, { [field]: Reflect.get(raw, field) })); }
    catch { record.issues.push({ field, code: 'invalid_value' }); }
  }
  const inactive = new Set<string>();
  if (data.ongoing === true) inactive.add('endedMonth');
  if (data.lifetime === true) inactive.add('expiresOn');
  if (data.hasAdditionalMajor === false) {
    inactive.add('additionalMajor'); inactive.add('additionalMajorType');
  }
  for (const field of inactive) delete data[field];
  record.issues = record.issues.filter(issue => !issue.field || !inactive.has(issue.field));
  const exclude = (field: string, code: AnalysisIssue['code']) => {
    if (!present(data[field])) return;
    delete data[field]; record.issues.push({ field, code });
  };
  for (const [start, end] of [['startedMonth', 'endedMonth'], ['startedOn', 'completedOn'], ['acquiredOn', 'expiresOn']]) {
    if (typeof data[start] === 'string' && typeof data[end] === 'string' && data[start] > data[end]) {
      exclude(start, 'inconsistent_range'); exclude(end, 'inconsistent_range');
    }
  }
  if (spec.type === SpecType.LANGUAGE_SCORE) {
    if (!data.exam) { exclude('score', 'missing_context'); exclude('grade', 'missing_context'); }
    if (data.exam === 'TOEIC' && typeof data.score === 'number' && data.score > 990) exclude('score', 'invalid_value');
  }
  if (spec.type === SpecType.EDUCATION_RECORD) {
    for (const field of ['gpa', 'majorGpa']) {
      if (typeof data[field] !== 'number') continue;
      if (typeof data.gpaScale !== 'number') exclude(field, 'missing_context');
      else if (data[field] > data.gpaScale) exclude(field, 'invalid_value');
    }
  }
  record.facts = fields.filter(field => present(data[field])).map(field => ({ field, path: `data.${field}`, value: data[field] }));
  record.missingFields = fields.filter(field => !inactive.has(field) && !present(data[field]));
  record.missingContext = CONTEXT_GROUPS[spec.type].filter(group => !group.some(field => present(data[field]))).map(group => [...group]);
  record.status = record.issues.length ? 'partial' : !record.facts.length ? 'empty' : record.missingContext.length ? 'partial' : 'available';
  return record;
}
