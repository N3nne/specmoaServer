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

@Entity({ name: 'certification_details' })
@Index(['certification', 'infoType'], { unique: true })
export class CertificationDetailEntity {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @ManyToOne(() => CertificationEntity, (certification) => certification.details, {
    onDelete: 'CASCADE',
  })
  certification: CertificationEntity;

  @Column()
  infoType: string;

  @Column({ type: 'text' })
  contents: string;

  @Column({ nullable: true })
  majorFieldCode?: string;

  @Column({ nullable: true })
  majorFieldName?: string;

  @Column({ nullable: true })
  middleFieldCode?: string;

  @Column({ nullable: true })
  middleFieldName?: string;

  @Column({ type: 'jsonb', default: {} })
  rawPayload: Record<string, unknown>;

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;
}
