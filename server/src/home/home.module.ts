import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';

import { CommunityQnaPostEntity } from '../community/entities/community-qna-post.entity';
import { SuccessStoryEntity } from '../community/entities/success-story.entity';
import { CertificationRoundPassRateStatEntity } from '../certifications/entities/certification-round-pass-rate-stat.entity';
import { ExamScheduleEntity } from '../certifications/entities/exam-schedule.entity';
import { UserCertificationEntity } from '../certifications/entities/user-certification.entity';
import { UsersModule } from '../users/users.module';
import { HomeController } from './home.controller';
import { HomeService } from './home.service';

@Module({
  imports: [
    TypeOrmModule.forFeature([
      CertificationRoundPassRateStatEntity,
      CommunityQnaPostEntity,
      ExamScheduleEntity,
      SuccessStoryEntity,
      UserCertificationEntity,
    ]),
    UsersModule,
  ],
  controllers: [HomeController],
  providers: [HomeService],
})
export class HomeModule {}
