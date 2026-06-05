import {
  Column,
  CreateDateColumn,
  Entity,
  Index,
  ManyToOne,
  PrimaryGeneratedColumn,
  UpdateDateColumn,
} from 'typeorm';

import { UserEntity } from '../../users/entities/user.entity';
import { CommunityQnaPostEntity } from './community-qna-post.entity';

@Entity({ name: 'community_qna_answers' })
@Index(['post', 'createdAt'])
export class CommunityQnaAnswerEntity {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @ManyToOne(() => CommunityQnaPostEntity, (post) => post.answers, {
    onDelete: 'CASCADE',
  })
  post: CommunityQnaPostEntity;

  @ManyToOne(() => UserEntity, { nullable: true, onDelete: 'SET NULL' })
  author?: UserEntity;

  @Column({ type: 'text' })
  body: string;

  @Column({ type: 'int', default: 0 })
  likeCount: number;

  @Column({ type: 'jsonb', default: {} })
  metadata: Record<string, unknown>;

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;
}
