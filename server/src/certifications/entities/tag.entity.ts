import {
  Column,
  CreateDateColumn,
  Entity,
  Index,
  OneToMany,
  PrimaryGeneratedColumn,
  UpdateDateColumn,
} from 'typeorm';

import { CertificationTagMappingEntity } from './certification-tag-mapping.entity';
import { CommunityQnaPostTagMappingEntity } from '../../community/entities/community-qna-post-tag-mapping.entity';

export enum TagType {
  QUALIFICATION_TYPE = 'qualification_type',
  GRADE = 'grade',
  FIELD = 'field',
  SUBFIELD = 'subfield',
  SERIES = 'series',
  KEYWORD = 'keyword',
  MANUAL = 'manual',
}

@Entity({ name: 'tags' })
@Index(['type', 'slug'], { unique: true })
export class TagEntity {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({
    type: 'enum',
    enum: TagType,
  })
  type: TagType;

  @Column()
  name: string;

  @Column()
  slug: string;

  @Column({ type: 'text', nullable: true })
  description?: string;

  @Column({ type: 'jsonb', default: {} })
  metadata: Record<string, unknown>;

  @OneToMany(() => CertificationTagMappingEntity, (mapping) => mapping.tag)
  certificationMappings: CertificationTagMappingEntity[];

  @OneToMany(() => CommunityQnaPostTagMappingEntity, (mapping) => mapping.tag)
  qnaPostMappings: CommunityQnaPostTagMappingEntity[];

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;
}
