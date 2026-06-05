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

@Entity({ name: 'study_tasks' })
export class StudyTaskEntity {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @ManyToOne(() => UserEntity, (user) => user.studyTasks, { onDelete: 'CASCADE' })
  user: UserEntity;

  @ManyToOne(() => CertificationEntity, { nullable: true })
  certification?: CertificationEntity;

  @Column()
  title: string;

  @Column({ type: 'int', default: 30 })
  minutes: number;

  @Column({ type: 'date' })
  dueDate: string;

  @Column({ type: 'timestamptz', nullable: true })
  completedAt?: Date;

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;
}
