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
import { TagEntity } from './tag.entity';

export enum TagSource {
  QNET = 'qnet',
  NAME_RULE = 'name_rule',
  MANUAL = 'manual',
}

@Entity({ name: 'certification_tag_mappings' })
@Index(['certification', 'tag'], { unique: true })
@Index(['tag'])
export class CertificationTagMappingEntity {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @ManyToOne(() => CertificationEntity, (certification) => certification.tagMappings, {
    onDelete: 'CASCADE',
  })
  certification: CertificationEntity;

  @ManyToOne(() => TagEntity, (tag) => tag.certificationMappings, { onDelete: 'CASCADE' })
  tag: TagEntity;

  @Column({
    type: 'enum',
    enum: TagSource,
    default: TagSource.QNET,
  })
  source: TagSource;

  @Column({ type: 'numeric', precision: 5, scale: 2, default: 1 })
  confidence: number;

  @Column({ type: 'jsonb', default: {} })
  metadata: Record<string, unknown>;

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;
}
