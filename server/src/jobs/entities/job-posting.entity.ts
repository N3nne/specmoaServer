import { Column, CreateDateColumn, Entity, Index, PrimaryGeneratedColumn, UpdateDateColumn } from 'typeorm';
import { EducationLevel, EmploymentType, ExperienceLevel, JobFeedItem, JobRequirement } from '../job.types';

@Entity({ name: 'job_postings' })
@Index('UQ_job_postings_source_external', ['source', 'externalId'], { unique: true })
@Index('IDX_job_postings_source_posted', ['source', 'postedAt'])
export class JobPostingEntity implements JobFeedItem {
  @PrimaryGeneratedColumn('uuid') id: string;
  @Column({ type: 'varchar' }) source: string;
  @Column({ type: 'boolean' }) synthetic: boolean;
  @Column({ type: 'text' }) notice: string;
  @Column({ type: 'varchar', nullable: true }) datasetVersion: string | null;
  @Column({ type: 'varchar' }) externalId: string;
  @Column({ type: 'varchar' }) companyName: string;
  @Column({ type: 'varchar' }) title: string;
  @Column({ type: 'varchar' }) occupation: string;
  @Column({ type: 'varchar' }) region: string;
  @Column({ type: 'varchar' }) employmentType: EmploymentType;
  @Column({ type: 'varchar', nullable: true }) educationLevel: EducationLevel | null;
  @Column({ type: 'varchar', nullable: true }) experienceLevel: ExperienceLevel | null;
  @Column({ type: 'int', nullable: true }) minExperienceMonths: number | null;
  @Column({ type: 'text', nullable: true }) salaryText: string | null;
  @Column({ type: 'jsonb', default: [] }) keywords: string[];
  @Column({ type: 'timestamptz' }) postedAt: Date;
  @Column({ type: 'timestamptz' }) opensAt: Date;
  @Column({ type: 'timestamptz', nullable: true }) closesAt: Date | null;
  @Column({ type: 'boolean' }) active: boolean;
  @Column({ type: 'text', nullable: true }) sourceUrl: string | null;
  @Column({ type: 'text', nullable: true }) description: string | null;
  @Column({ type: 'jsonb', nullable: true }) requirements: JobRequirement[] | null;
  @Column({ type: 'timestamptz' }) fetchedAt: Date;
  @CreateDateColumn({ type: 'timestamptz' }) createdAt: Date;
  @UpdateDateColumn({ type: 'timestamptz' }) updatedAt: Date;
}
