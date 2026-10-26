import dataSource from '../database/data-source';
import { JobPostingEntity } from './entities/job-posting.entity';
import { importJobs } from './job-import';
import { DemoJobSource } from './providers/demo-job.source';

async function seed() {
  const url = new URL(process.env.DATABASE_URL!);
  if (!['localhost', '127.0.0.1', '::1', '[::1]'].includes(url.hostname) || process.env.NODE_ENV === 'production') {
    throw new Error('Demo seeding is restricted to a local development database.');
  }
  const date = process.argv[2];
  if (date && !/^\d{4}-\d{2}-\d{2}$/.test(date)) throw new Error('Use YYYY-MM-DD for the optional KST reference date.');
  const asOf = date ? new Date(`${date}T00:00:00+09:00`) : new Date();
  if (!Number.isFinite(asOf.getTime()) || date && new Date(asOf.getTime() + 9 * 60 * 60 * 1000).toISOString().slice(0, 10) !== date) throw new Error('Invalid reference date.');
  await dataSource.initialize();
  try {
    const result = await importJobs(dataSource.getRepository(JobPostingEntity), new DemoJobSource(), asOf);
    console.log(JSON.stringify(result));
  } finally {
    await dataSource.destroy();
  }
}

void seed().catch(() => {
  console.error('Demo seed failed. Verify local DB, reference date and db:migrate; credentials were not printed.');
  process.exitCode = 1;
});
