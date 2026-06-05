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

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true }),
    TypeOrmModule.forRootAsync({ useFactory: databaseConfig }),
    AuthModule,
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
