import {
  Column,
  CreateDateColumn,
  Entity,
  Index,
  PrimaryGeneratedColumn,
  UpdateDateColumn,
} from 'typeorm';

@Entity({ name: 'certification_major_stats' })
@Index(['externalSource', 'externalId'], { unique: true })
export class CertificationMajorStatEntity {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column()
  externalSource: string;

  @Column()
  externalId: string;

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

  @Column({ nullable: true })
  middleFieldCode?: string;

  @Column({ nullable: true })
  middleFieldName?: string;

  @Column()
  majorYnCode: string;

  @Column({ type: 'int', default: 0 })
  accumulatedAcquiredCount: number;

  @Column({ type: 'int', default: 0 })
  year1AcquiredCount: number;

  @Column({ type: 'int', default: 0 })
  year2AcquiredCount: number;

  @Column({ type: 'int', default: 0 })
  year3AcquiredCount: number;

  @Column({ type: 'int', default: 0 })
  year4AcquiredCount: number;

  @Column({ type: 'int', default: 0 })
  year5AcquiredCount: number;

  @Column({ type: 'int', default: 0 })
  year6AcquiredCount: number;

  @Column({ type: 'jsonb', default: {} })
  rawPayload: Record<string, unknown>;

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;
}
