import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { UserSpecEntity } from '../specs/entities/user-spec.entity';
import { JobPostingEntity } from './entities/job-posting.entity';
import { JOB_SOURCE } from './job.types';
import { JobsController } from './jobs.controller';
import { JobsService } from './jobs.service';
import { configuredJobSource } from './providers/job-source.factory';

@Module({
  imports: [TypeOrmModule.forFeature([JobPostingEntity, UserSpecEntity])],
  controllers: [JobsController],
  providers: [JobsService, { provide: JOB_SOURCE, useFactory: configuredJobSource }],
})
export class JobsModule {}
