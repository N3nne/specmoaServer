import { Repository } from 'typeorm';
import { JobPostingEntity } from './entities/job-posting.entity';
import { EducationLevel, EmploymentType, ExperienceLevel, JobFeedItem, JobSource } from './job.types';

const feedFields: (keyof JobFeedItem)[] = [
  'externalId', 'companyName', 'title', 'occupation', 'region', 'employmentType', 'educationLevel', 'experienceLevel',
  'minExperienceMonths', 'salaryText', 'keywords', 'postedAt', 'opensAt', 'closesAt', 'active', 'sourceUrl', 'description', 'requirements',
];

function validateItem(item: JobFeedItem, source: JobSource) {
  for (const key of ['externalId', 'companyName', 'title', 'occupation', 'region'] as const) {
    if (typeof item[key] !== 'string' || !item[key].trim() || item[key].length > 255) throw new Error(`Invalid job ${key}.`);
  }
  if (!Object.values(EmploymentType).includes(item.employmentType) ||
      item.educationLevel !== null && !Object.values(EducationLevel).includes(item.educationLevel) ||
      item.experienceLevel !== null && !Object.values(ExperienceLevel).includes(item.experienceLevel)) throw new Error('Invalid job classification.');
  if (typeof item.active !== 'boolean' || item.minExperienceMonths !== null &&
      (!Number.isInteger(item.minExperienceMonths) || item.minExperienceMonths < 0)) throw new Error('Invalid job conditions.');
  if (item.salaryText !== null && typeof item.salaryText !== 'string' || item.description !== null && typeof item.description !== 'string') throw new Error('Invalid job text.');
  if (item.closesAt === undefined) throw new Error('Unknown job deadline must be null.');
  if (![item.postedAt, item.opensAt, ...(item.closesAt !== null ? [item.closesAt] : [])].every(date => date instanceof Date && Number.isFinite(date.getTime()))) {
    throw new Error('Invalid job timestamp.');
  }
  if (item.closesAt && item.closesAt < item.opensAt) throw new Error('Job closes before it opens.');
  if (source.synthetic && item.sourceUrl !== null) throw new Error('Synthetic jobs cannot link to a real application form.');
  if (item.sourceUrl !== null) {
    const url = new URL(item.sourceUrl);
    if (!['http:', 'https:'].includes(url.protocol) || url.username || url.password) throw new Error('Invalid source URL.');
  }
  if (!Array.isArray(item.keywords) || !item.keywords.every(keyword => typeof keyword === 'string')) throw new Error('Invalid job keywords.');
  if (item.requirements !== null && (!Array.isArray(item.requirements) || item.requirements.some(rule =>
    !['skill', 'certification', 'language_score'].includes(rule.kind) || typeof rule.name !== 'string' || !rule.name.trim() ||
    typeof rule.required !== 'boolean' || rule.minimumScore !== undefined &&
      (rule.kind !== 'language_score' || !Number.isFinite(rule.minimumScore) || rule.minimumScore < 0)))) throw new Error('Invalid detailed job requirements.');
}

export async function importJobs(repository: Repository<JobPostingEntity>, source: JobSource, asOf: Date) {
  if (!Number.isFinite(asOf.getTime()) || !/^[a-z][a-z0-9_-]{0,39}$/.test(source.source) || !source.notice || typeof source.synthetic !== 'boolean' ||
      source.source === 'demo' && !source.synthetic) throw new Error('Invalid job source metadata.');
  const items = await source.load(asOf);
  const ids = new Set<string>();
  for (const item of items) {
    validateItem(item, source);
    if (ids.has(item.externalId)) throw new Error('Duplicate external job ID in feed.');
    ids.add(item.externalId);
  }
  if (items.length) {
    await repository.manager.transaction(async manager => {
      await manager.getRepository(JobPostingEntity).upsert(items.map(item => ({
        ...Object.fromEntries(feedFields.map(key => [key, item[key]])),
        source: source.source, synthetic: source.synthetic, notice: source.notice,
        datasetVersion: source.datasetVersion, fetchedAt: asOf,
      })), { conflictPaths: ['source', 'externalId'], skipUpdateIfNoValuesChanged: true });
    });
  }
  return { source: source.source, synthetic: source.synthetic, imported: items.length, asOf: asOf.toISOString(), datasetVersion: source.datasetVersion };
}
