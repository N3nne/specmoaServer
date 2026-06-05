import {
  Column,
  CreateDateColumn,
  Entity,
  ManyToOne,
  PrimaryGeneratedColumn,
  UpdateDateColumn,
} from 'typeorm';

import { CertificationEntity } from '../../certifications/entities/certification.entity';
import { UserEntity } from '../../users/entities/user.entity';

@Entity({ name: 'study_sessions' })
export class StudySessionEntity {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @ManyToOne(() => UserEntity, (user) => user.studySessions, { onDelete: 'CASCADE' })
  user: UserEntity;

  @ManyToOne(() => CertificationEntity, { nullable: true })
  certification?: CertificationEntity;

  @Column({ type: 'timestamptz' })
  startedAt: Date;

  @Column({ type: 'timestamptz', nullable: true })
  endedAt?: Date;

  @Column({ type: 'int', default: 0 })
  durationSeconds: number;

  @Column({ type: 'text', nullable: true })
  note?: string;

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;
}
