import {
  Column,
  CreateDateColumn,
  Entity,
  Index,
  PrimaryGeneratedColumn,
  UpdateDateColumn,
} from 'typeorm';

@Entity({ name: 'certification_acquisition_stats' })
@Index(['externalSource', 'externalId'], { unique: true })
export class CertificationAcquisitionStatEntity {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column()
  externalSource: string;

  @Column()
  externalId: string;

  @Column({ type: 'int' })
  baseYear: number;

  @Column({ type: 'int' })
  implementationYear: number;

  @Column()
  reportGroup: string;

  @Column()
  reportGroupName: string;

  @Column({ type: 'int', default: 0 })
  issuedCount: number;

  @Column({ type: 'int', default: 0 })
  notIssuedCount: number;

  @Column({ type: 'int', default: 0 })
  totalCount: number;

  @Column({ type: 'jsonb', default: {} })
  rawPayload: Record<string, unknown>;

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;
}
