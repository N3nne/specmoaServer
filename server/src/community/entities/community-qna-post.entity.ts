import {
  Column,
  CreateDateColumn,
  Entity,
  Index,
  ManyToOne,
  OneToMany,
  PrimaryGeneratedColumn,
  UpdateDateColumn,
} from 'typeorm';

import { CertificationEntity } from '../../certifications/entities/certification.entity';
import { UserEntity } from '../../users/entities/user.entity';
import { CommunityQnaAnswerEntity } from './community-qna-answer.entity';
import { CommunityQnaPostTagMappingEntity } from './community-qna-post-tag-mapping.entity';

export enum CommunityQnaStatus {
  OPEN = 'open',
  ANSWERED = 'answered',
  CLOSED = 'closed',
  HIDDEN = 'hidden',
}

@Entity({ name: 'community_qna_posts' })
@Index(['status', 'createdAt'])
@Index(['certification'])
export class CommunityQnaPostEntity {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @ManyToOne(() => UserEntity, (user) => user.qnaPosts, { nullable: true, onDelete: 'SET NULL' })
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
    enum: CommunityQnaStatus,
    default: CommunityQnaStatus.OPEN,
  })
  status: CommunityQnaStatus;

  @Column({ type: 'int', default: 0 })
  viewCount: number;

  @Column({ type: 'int', default: 0 })
  likeCount: number;

  @Column({ type: 'int', default: 0 })
  answerCount: number;

  @Column({ nullable: true })
  acceptedAnswerId?: string;

  @Column({ type: 'jsonb', default: {} })
  metadata: Record<string, unknown>;

  @OneToMany(() => CommunityQnaPostTagMappingEntity, (mapping) => mapping.post)
  tagMappings: CommunityQnaPostTagMappingEntity[];

  @OneToMany(() => CommunityQnaAnswerEntity, (answer) => answer.post)
  answers: CommunityQnaAnswerEntity[];

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;
}
