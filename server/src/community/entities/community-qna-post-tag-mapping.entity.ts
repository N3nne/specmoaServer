import {
  CreateDateColumn,
  Entity,
  Index,
  ManyToOne,
  PrimaryGeneratedColumn,
  UpdateDateColumn,
} from 'typeorm';

import { TagEntity } from '../../certifications/entities/tag.entity';
import { CommunityQnaPostEntity } from './community-qna-post.entity';

@Entity({ name: 'community_qna_post_tag_mappings' })
@Index(['post', 'tag'], { unique: true })
@Index(['tag'])
export class CommunityQnaPostTagMappingEntity {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @ManyToOne(() => CommunityQnaPostEntity, (post) => post.tagMappings, { onDelete: 'CASCADE' })
  post: CommunityQnaPostEntity;

  @ManyToOne(() => TagEntity, (tag) => tag.qnaPostMappings, { onDelete: 'CASCADE' })
  tag: TagEntity;

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;
}
