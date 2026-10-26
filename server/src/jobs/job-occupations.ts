// Internal codes, not a government occupation classification. External feeds need an explicit mapping.
export const OCCUPATION_LABELS = {
  backend: '백엔드 개발',
  frontend: '프론트엔드 개발',
  mobile: '모바일 앱 개발',
  data: '데이터 분석',
  design: 'UX/UI 디자인',
  marketing: '디지털 마케팅',
  accounting: '회계·재무',
  electrical: '전기설비 관리',
  safety: '산업안전 관리',
  mechanical: '기계설계',
} as const;

export type JobOccupation = keyof typeof OCCUPATION_LABELS;
export const JOB_OCCUPATION_CODES = Object.keys(OCCUPATION_LABELS) as JobOccupation[];
export const JOB_OCCUPATIONS = JOB_OCCUPATION_CODES.map(code => ({ code, label: OCCUPATION_LABELS[code] }));
