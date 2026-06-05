import {
  Column,
  CreateDateColumn,
  Entity,
  OneToMany,
  OneToOne,
  PrimaryGeneratedColumn,
  UpdateDateColumn,
} from 'typeorm';

import { UserCertificationEntity } from '../../certifications/entities/user-certification.entity';
import { CommunityQnaPostEntity } from '../../community/entities/community-qna-post.entity';
import { SuccessStoryEntity } from '../../community/entities/success-story.entity';
import { StudySessionEntity } from '../../study-sessions/entities/study-session.entity';
import { StudyTaskEntity } from '../../study-tasks/entities/study-task.entity';
import { UserProfileEntity } from './user-profile.entity';

@Entity({ name: 'users' })
export class UserEntity {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ unique: true })
  email: string;

  @Column()
  displayName: string;

  @Column({ default: 'local' })
  authProvider: string;

  @Column({ nullable: true, select: false })
  passwordHash?: string;

  @OneToOne(() => UserProfileEntity, (profile) => profile.user)
  profile?: UserProfileEntity;

  @OneToMany(() => UserCertificationEntity, (item) => item.user)
  certifications: UserCertificationEntity[];

  @OneToMany(() => StudyTaskEntity, (task) => task.user)
  studyTasks: StudyTaskEntity[];

  @OneToMany(() => StudySessionEntity, (session) => session.user)
  studySessions: StudySessionEntity[];

  @OneToMany(() => CommunityQnaPostEntity, (post) => post.author)
  qnaPosts: CommunityQnaPostEntity[];

  @OneToMany(() => SuccessStoryEntity, (story) => story.author)
  successStories: SuccessStoryEntity[];

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;
}
