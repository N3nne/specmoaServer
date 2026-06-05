export type ExternalExamSchedule = {
  type: 'registration' | 'written' | 'practical' | 'result';
  title: string;
  startsOn: string;
  endsOn?: string;
  rawPayload?: Record<string, unknown>;
};

export type ExternalCertification = {
  externalSource: string;
  externalId: string;
  name: string;
  englishName?: string;
  category: string;
  organization?: string;
  description?: string;
  officialUrl?: string;
  rawPayload?: Record<string, unknown>;
  schedules?: ExternalExamSchedule[];
};
