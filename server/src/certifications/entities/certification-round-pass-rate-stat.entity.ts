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

@Entity({ name: 'certification_round_pass_rate_stats' })
@Index(['externalSource', 'externalId'], { unique: true })
@Index(['jmCd', 'baseYear'])
export class CertificationRoundPassRateStatEntity {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column()
  externalSource: string;

  @Column()
  externalId: string;

  @ManyToOne(() => CertificationEntity, { nullable: true, onDelete: 'SET NULL' })
  certification?: CertificationEntity;

  @Column({ type: 'int' })
  baseYear: number;

  @Column()
  jmCd: string;

  @Column()
  jmName: string;

  @Column()
  gradeCode: string;

  @Column()
  gradeName: string;

  @Column({ type: 'int' })
  implementationYear: number;

  @Column()
  implementationSeq: string;

  @Column()
  examType: string;

  @Column({ type: 'int', default: 0 })
  examineeCount: number;

  @Column({ type: 'int', default: 0 })
  passCount: number;

  @Column({ type: 'numeric', precision: 8, scale: 4, default: 0 })
  passRate: number;

  @Column({ type: 'jsonb', default: {} })
  rawPayload: Record<string, unknown>;

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;
}
