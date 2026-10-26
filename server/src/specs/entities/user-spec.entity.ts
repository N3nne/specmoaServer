import { Column, CreateDateColumn, Entity, Index, JoinColumn, ManyToOne, PrimaryGeneratedColumn, UpdateDateColumn } from 'typeorm';
import { CertificationEntity } from '../../certifications/entities/certification.entity';
import { UserEntity } from '../../users/entities/user.entity';
import { SpecData, SpecType } from '../spec-types';

@Entity({ name: 'user_specs' })
@Index(['userId', 'type', 'createdAt'])
export class UserSpecEntity {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ type: 'uuid' })
  userId: string;

  @ManyToOne(() => UserEntity, { onDelete: 'CASCADE', nullable: false })
  @JoinColumn({ name: 'userId' })
  user: UserEntity;

  @Column({ type: 'varchar' })
  type: SpecType;

  @Column({ type: 'text', nullable: true })
  title: string | null;

  @Column({ type: 'jsonb', default: {} })
  data: SpecData;

  @Column({ type: 'uuid', nullable: true })
  certificationId: string | null;

  @ManyToOne(() => CertificationEntity, { nullable: true, onDelete: 'SET NULL' })
  @JoinColumn({ name: 'certificationId' })
  certification: CertificationEntity | null;

  @Column({ type: 'uuid', nullable: true, unique: true })
  legacyUserCertificationId: string | null;

  @CreateDateColumn({ type: 'timestamptz' })
  createdAt: Date;

  @UpdateDateColumn({ type: 'timestamptz' })
  updatedAt: Date;
}
