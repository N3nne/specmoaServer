import {
  Column,
  CreateDateColumn,
  Entity,
  Index,
  PrimaryGeneratedColumn,
  UpdateDateColumn,
} from 'typeorm';

@Entity({ name: 'exam_eligibilities' })
@Index(['externalSource', 'externalId'], { unique: true })
export class ExamEligibilityEntity {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column()
  externalSource: string;

  @Column()
  externalId: string;

  @Column()
  eligibilityCode: string;

  @Column({ type: 'text' })
  eligibilityName: string;

  @Column()
  gradeCode: string;

  @Column()
  gradeName: string;

  @Column()
  qualificationTypeCode: string;

  @Column()
  qualificationTypeName: string;

  @Column({ type: 'jsonb', default: {} })
  rawPayload: Record<string, unknown>;

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;
}
