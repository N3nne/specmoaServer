import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';

import { CertificationEntity } from '../certifications/entities/certification.entity';
import { UsersModule } from '../users/users.module';
import { StudySessionEntity } from './entities/study-session.entity';
import { StudySessionsController } from './study-sessions.controller';
import { StudySessionsService } from './study-sessions.service';

@Module({
  imports: [TypeOrmModule.forFeature([StudySessionEntity, CertificationEntity]), UsersModule],
  controllers: [StudySessionsController],
  providers: [StudySessionsService],
})
export class StudySessionsModule {}
