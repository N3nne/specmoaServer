import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';

import { CertificationEntity } from '../certifications/entities/certification.entity';
import { UsersModule } from '../users/users.module';
import { StudyTaskEntity } from './entities/study-task.entity';
import { StudyTasksController } from './study-tasks.controller';
import { StudyTasksService } from './study-tasks.service';

@Module({
  imports: [TypeOrmModule.forFeature([StudyTaskEntity, CertificationEntity]), UsersModule],
  controllers: [StudyTasksController],
  providers: [StudyTasksService],
})
export class StudyTasksModule {}
