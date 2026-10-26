import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { TypeOrmModule } from '@nestjs/typeorm';

import { AppController } from './app.controller';
import { AuthModule } from './auth/auth.module';
import { CommunityModule } from './community/community.module';
import { CertificationsModule } from './certifications/certifications.module';
import { databaseConfig } from './config/database.config';
import { HomeModule } from './home/home.module';
import { StudySessionsModule } from './study-sessions/study-sessions.module';
import { StudyTasksModule } from './study-tasks/study-tasks.module';
import { UsersModule } from './users/users.module';
import { SpecsModule } from './specs/specs.module';
import { JobsModule } from './jobs/jobs.module';
import { AiModule } from './ai/ai.module';
import { CareerModule } from './career/career.module';

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true }),
    TypeOrmModule.forRootAsync({ useFactory: databaseConfig }),
    AuthModule,
    SpecsModule,
    JobsModule,
    AiModule,
    CareerModule,
    UsersModule,
    CertificationsModule,
    CommunityModule,
    HomeModule,
    StudyTasksModule,
    StudySessionsModule,
  ],
  controllers: [AppController],
})
export class AppModule {}
