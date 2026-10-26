import { JobSource } from '../job.types';
import { DemoJobSource } from './demo-job.source';

export function configuredJobSource(env: NodeJS.ProcessEnv = process.env): JobSource {
  const source = env.JOBS_SOURCE || (env.NODE_ENV === 'production' ? 'disabled' : 'demo');
  if (source === 'demo') return new DemoJobSource();
  if (source === 'disabled') return {
    source, synthetic: false, notice: '채용정보 연동이 비활성화되어 있습니다.', datasetVersion: null,
    load: async () => [],
  };
  // Register a real provider here only after authorization and payload mapping are verified.
  throw new Error(`JOBS_SOURCE=${source} is not implemented. No demo fallback was used.`);
}
