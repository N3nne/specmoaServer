import {
  Column,
  CreateDateColumn,
  Entity,
  Index,
  PrimaryGeneratedColumn,
  UpdateDateColumn,
} from 'typeorm';

@Entity({ name: 'certification_pass_rate_stats' })
@Index(['externalSource', 'externalId'], { unique: true })
export class CertificationPassRateStatEntity {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column()
  externalSource: string;

  @Column()
  externalId: string;

  @Column({ type: 'int' })
  baseYear: number;

  @Column()
  gradeCode: string;

  @Column()
  gradeName: string;

  @Column({ type: 'int' })
  implementationYear: number;

  @Column()
  implementationSeq: string;

  @Column({ type: 'text' })
  eligibilityName: string;

  @Column({ type: 'int', default: 0 })
  receptionCount: number;

  @Column({ type: 'int', default: 0 })
  writtenPassCount: number;

  @Column({ type: 'int', default: 0 })
  practicalPassCount: number;

  @Column({ type: 'numeric', precision: 8, scale: 4, default: 0 })
  writtenPassRate: number;

  @Column({ type: 'numeric', precision: 8, scale: 4, default: 0 })
  practicalPassRate: number;

  @Column({ type: 'jsonb', default: {} })
  rawPayload: Record<string, unknown>;

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;
}
