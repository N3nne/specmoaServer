import {
  Column,
  CreateDateColumn,
  Entity,
  JoinColumn,
  OneToOne,
  PrimaryGeneratedColumn,
  UpdateDateColumn,
} from 'typeorm';

import { UserEntity } from './user.entity';

@Entity({ name: 'user_profiles' })
export class UserProfileEntity {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @OneToOne(() => UserEntity, (user) => user.profile, { onDelete: 'CASCADE' })
  @JoinColumn()
  user: UserEntity;

  @Column({ nullable: true })
  nickname?: string;

  @Column({ nullable: true })
  phoneNumber?: string;

  @Column({ type: 'int', nullable: true })
  birthYear?: number;

  @Column({ nullable: true })
  educationLevel?: string;

  @Column({ nullable: true })
  majorName?: string;

  @Column({ nullable: true })
  careerLevel?: string;

  @Column({ type: 'text', array: true, default: () => "'{}'" })
  interestTags: string[];

  @Column({ type: 'jsonb', default: {} })
  preferences: Record<string, unknown>;

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;
}
