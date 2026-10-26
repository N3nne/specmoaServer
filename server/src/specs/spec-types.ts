export enum SpecType {
  CERTIFICATION = 'certification',
  LANGUAGE_SCORE = 'language_score',
  EDUCATION_RECORD = 'education_record',
  AWARD = 'award',
  PROJECT = 'project',
  WORK_EXPERIENCE = 'work_experience',
  EXTERNAL_ACTIVITY = 'external_activity',
  TRAINING = 'training',
}

export type SpecData = Record<string, string | number | boolean | string[] | number[] | null>;

export function specGroup(type: SpecType) {
  return [SpecType.CERTIFICATION, SpecType.LANGUAGE_SCORE, SpecType.EDUCATION_RECORD, SpecType.AWARD].includes(type)
    ? 'exam_score' : 'activity_experience';
}
