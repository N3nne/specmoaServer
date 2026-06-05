import {
  Column,
  CreateDateColumn,
  Entity,
  Index,
  OneToMany,
  PrimaryGeneratedColumn,
  UpdateDateColumn,
} from 'typeorm';

import { ExamScheduleEntity } from './exam-schedule.entity';
import { CertificationDetailEntity } from './certification-detail.entity';
import { CertificationTagMappingEntity } from './certification-tag-mapping.entity';
import { UserCertificationEntity } from './user-certification.entity';

@Entity({ name: 'certifications' })
@Index(['externalSource', 'externalId'], { unique: true })
export class CertificationEntity {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column()
  externalSource: string;

  @Column()
  externalId: string;

  @Column()
  name: string;

  @Column({ nullable: true })
  englishName?: string;

  @Column()
  category: string;

  @Column({ nullable: true })
  organization?: string;

  @Column({ type: 'text', nullable: true })
  description?: string;

  @Column({ nullable: true })
  officialUrl?: string;

  @Column({ type: 'jsonb', default: {} })
  rawPayload: Record<string, unknown>;

  @OneToMany(() => ExamScheduleEntity, (schedule) => schedule.certification)
  schedules: ExamScheduleEntity[];

  @OneToMany(() => CertificationDetailEntity, (detail) => detail.certification)
  details: CertificationDetailEntity[];

  @OneToMany(() => UserCertificationEntity, (item) => item.certification)
  userCertifications: UserCertificationEntity[];

  @OneToMany(() => CertificationTagMappingEntity, (mapping) => mapping.certification)
  tagMappings: CertificationTagMappingEntity[];

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;
}
