import {
  Column,
  CreateDateColumn,
  Entity,
  ManyToOne,
  PrimaryGeneratedColumn,
  UpdateDateColumn,
} from 'typeorm';

import { UserEntity } from '../../users/entities/user.entity';
import { CertificationEntity } from './certification.entity';

export enum UserCertificationStatus {
  PLANNED = 'planned',
  IN_PROGRESS = 'in_progress',
  CERTIFIED = 'certified',
  ARCHIVED = 'archived',
}

@Entity({ name: 'user_certifications' })
export class UserCertificationEntity {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @ManyToOne(() => UserEntity, (user) => user.certifications, { onDelete: 'CASCADE' })
  user: UserEntity;

  @ManyToOne(() => CertificationEntity, (certification) => certification.userCertifications)
  certification: CertificationEntity;

  @Column({
    type: 'enum',
    enum: UserCertificationStatus,
    default: UserCertificationStatus.PLANNED,
  })
  status: UserCertificationStatus;

  @Column({ type: 'int', default: 0 })
  progress: number;

  @Column({ type: 'date', nullable: true })
  targetExamDate?: string;

  @Column({ type: 'date', nullable: true })
  certifiedOn?: string;

  @Column({ nullable: true })
  certificateNumber?: string;

  @Column({ nullable: true })
  preparationCategory?: string;

  @Column({ type: 'text', nullable: true })
  notes?: string;

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;
}
