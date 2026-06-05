import {
  Column,
  CreateDateColumn,
  Entity,
  Index,
  ManyToOne,
  PrimaryGeneratedColumn,
  UpdateDateColumn,
} from 'typeorm';

import { CertificationEntity } from '../../certifications/entities/certification.entity';
import { UserEntity } from '../../users/entities/user.entity';

export enum SuccessStoryStatus {
  DRAFT = 'draft',
  PUBLISHED = 'published',
  HIDDEN = 'hidden',
}

@Entity({ name: 'success_stories' })
@Index(['status', 'createdAt'])
@Index(['certification'])
export class SuccessStoryEntity {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @ManyToOne(() => UserEntity, (user) => user.successStories, {
    nullable: true,
    onDelete: 'SET NULL',
  })
  author?: UserEntity;

  @ManyToOne(() => CertificationEntity, { nullable: true, onDelete: 'SET NULL' })
  certification?: CertificationEntity;

  @Column()
  title: string;

  @Column({ type: 'text' })
  body: string;

  @Column({ type: 'text', array: true, default: () => "'{}'" })
  tags: string[];

  @Column({
    type: 'enum',
    enum: SuccessStoryStatus,
    default: SuccessStoryStatus.PUBLISHED,
  })
  status: SuccessStoryStatus;

  @Column({ type: 'int', nullable: true })
  studyPeriodDays?: number;

  @Column({ nullable: true })
  examAttempt?: string;

  @Column({ type: 'date', nullable: true })
  passedOn?: string;

  @Column({ type: 'int', default: 0 })
  viewCount: number;

  @Column({ type: 'int', default: 0 })
  likeCount: number;

  @Column({ type: 'jsonb', default: {} })
  metadata: Record<string, unknown>;

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;
}
