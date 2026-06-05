import {
  Column,
  CreateDateColumn,
  Entity,
  Index,
  ManyToOne,
  PrimaryGeneratedColumn,
  UpdateDateColumn,
} from 'typeorm';

import { CertificationEntity } from './certification.entity';

export enum ExamScheduleType {
  REGISTRATION = 'registration',
  WRITTEN = 'written',
  PRACTICAL = 'practical',
  RESULT = 'result',
  CUSTOM = 'custom',
}

@Entity({ name: 'exam_schedules' })
@Index(['externalSource', 'externalId'], { unique: true })
export class ExamScheduleEntity {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @ManyToOne(() => CertificationEntity, (certification) => certification.schedules, {
    onDelete: 'CASCADE',
  })
  certification: CertificationEntity;

  @Column({ type: 'enum', enum: ExamScheduleType })
  type: ExamScheduleType;

  @Column()
  title: string;

  @Column({ type: 'date' })
  startsOn: string;

  @Column({ type: 'date', nullable: true })
  endsOn?: string;

  @Column({ default: 'external' })
  source: string;

  @Column({ nullable: true })
  externalSource?: string;

  @Column({ nullable: true })
  externalId?: string;

  @Column({ type: 'jsonb', default: {} })
  rawPayload: Record<string, unknown>;

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;
}
