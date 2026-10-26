import { Inject, Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { UserSpecEntity } from '../specs/entities/user-spec.entity';
import { ListJobsDto } from './dto/list-jobs.dto';
import { JobPostingEntity } from './entities/job-posting.entity';
import { compareJob } from './job-match';
import { JOB_SOURCE, JobSort, JobSource, JobStatus, jobStatus } from './job.types';

@Injectable()
export class JobsService {
  constructor(
    @InjectRepository(JobPostingEntity) private readonly jobs: Repository<JobPostingEntity>,
    @InjectRepository(UserSpecEntity) private readonly specs: Repository<UserSpecEntity>,
    @Inject(JOB_SOURCE) private readonly source: JobSource,
  ) {}

  async list(query: ListJobsDto) {
    const now = new Date();
    const builder = this.filtered(query, now);
    if (query.sort === JobSort.DEADLINE) builder.orderBy('job.closesAt', 'ASC', 'NULLS LAST');
    else builder.orderBy('job.postedAt', 'DESC');
    const [items, total] = await builder.addOrderBy('job.id', 'ASC').take(query.limit).skip(query.offset).getManyAndCount();
    return { ...this.metadata(), items: items.map(job => this.serialize(job, now)), total, limit: query.limit, offset: query.offset, asOf: now.toISOString() };
  }

  async facets(query: ListJobsDto) {
    const builder = this.filtered(query, new Date());
    const counts = async (key: 'occupation' | 'region' | 'employmentType' | 'educationLevel' | 'experienceLevel') => {
      const rows = await builder.clone().select(`job.${key}`, 'value').addSelect('COUNT(*)', 'count')
        .andWhere(`job.${key} IS NOT NULL`).groupBy(`job.${key}`).orderBy(`job.${key}`, 'ASC')
        .getRawMany<{ value: string; count: string }>();
      return rows.map(row => ({ value: row.value, count: Number(row.count) }));
    };
    return { ...this.metadata(), total: await builder.getCount(), occupations: await counts('occupation'), regions: await counts('region'),
      employmentTypes: await counts('employmentType'), educationLevels: await counts('educationLevel'), experienceLevels: await counts('experienceLevel') };
  }

  async detail(id: string) {
    return this.serialize(await this.find(id), new Date());
  }

  async demoDetail(externalId: string) {
    if (this.source.source !== 'demo' || !/^specmoa-demo-v1-\d{3}$/.test(externalId)) {
      throw new NotFoundException('가상 채용공고를 찾을 수 없습니다.');
    }
    const job = await this.jobs.findOneBy({ source: 'demo', externalId, synthetic: true });
    if (!job) throw new NotFoundException('가상 채용공고를 찾을 수 없습니다.');
    return this.serialize(job, new Date());
  }

  async match(userId: string, id: string) {
    const job = await this.find(id);
    const specs = await this.specs.findBy({ userId });
    const now = new Date();
    return { job: this.serialize(job, now), comparison: compareJob(job, specs, now) };
  }

  private async find(id: string) {
    const job = await this.jobs.findOneBy({ id, source: this.source.source });
    if (!job) throw new NotFoundException('채용공고를 찾을 수 없습니다.');
    return job;
  }

  private filtered(query: ListJobsDto, now: Date) {
    const builder = this.jobs.createQueryBuilder('job').where('job.source = :source', { source: this.source.source });
    if (query.q) {
      const q = `%${query.q.replace(/[\\%_]/g, '\\$&')}%`;
      builder.andWhere('(job.title ILIKE :q OR job.companyName ILIKE :q OR job.keywords::text ILIKE :q)', { q });
    }
    for (const field of ['occupation', 'region', 'employmentType', 'educationLevel', 'experienceLevel'] as const) {
      if (query[field]) builder.andWhere(`job.${field} = :${field}`, { [field]: query[field] });
    }
    if (query.status === JobStatus.OPEN) builder.andWhere('job.active = true AND job.opensAt <= :now AND (job.closesAt IS NULL OR job.closesAt > :now)', { now });
    else if (query.status === JobStatus.UPCOMING) builder.andWhere('job.active = true AND job.opensAt > :now AND (job.closesAt IS NULL OR job.closesAt > :now)', { now });
    else if (query.status === JobStatus.CLOSED) builder.andWhere('(job.active = false OR job.closesAt <= :now)', { now });
    return builder;
  }

  private metadata() {
    return { source: this.source.source, synthetic: this.source.synthetic, notice: this.source.notice };
  }

  private serialize(job: JobPostingEntity, now: Date) {
    return {
      id: job.id, source: job.source, externalId: job.externalId, synthetic: job.synthetic, notice: job.notice,
      datasetVersion: job.datasetVersion, companyName: job.companyName, title: job.title, occupation: job.occupation,
      region: job.region, employmentType: job.employmentType, educationLevel: job.educationLevel,
      experienceLevel: job.experienceLevel, minExperienceMonths: job.minExperienceMonths, salaryText: job.salaryText,
      keywords: job.keywords, postedAt: job.postedAt, opensAt: job.opensAt, closesAt: job.closesAt,
      status: jobStatus(job, now), sourceUrl: job.synthetic ? null : job.sourceUrl,
      canApply: !job.synthetic && job.sourceUrl !== null && jobStatus(job, now) === JobStatus.OPEN,
      description: job.description, requirements: job.requirements,
      requirementsOrigin: job.requirements === null ? 'unavailable' : job.synthetic ? 'synthetic' : 'provider',
      fetchedAt: job.fetchedAt,
    };
  }
}
