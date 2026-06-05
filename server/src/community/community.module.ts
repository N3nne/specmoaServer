import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';

import { CertificationEntity } from '../certifications/entities/certification.entity';
import { UserCertificationEntity } from '../certifications/entities/user-certification.entity';
import { TagEntity } from '../certifications/entities/tag.entity';
import { UsersModule } from '../users/users.module';
import { CommunityController } from './community.controller';
import { CommunityService } from './community.service';
import { CommunityQnaAnswerEntity } from './entities/community-qna-answer.entity';
import { CommunityQnaPostEntity } from './entities/community-qna-post.entity';
import { CommunityQnaPostTagMappingEntity } from './entities/community-qna-post-tag-mapping.entity';
import { SuccessStoryEntity } from './entities/success-story.entity';

@Module({
  imports: [
    UsersModule,
    TypeOrmModule.forFeature([
      CertificationEntity,
      CommunityQnaAnswerEntity,
      CommunityQnaPostEntity,
      CommunityQnaPostTagMappingEntity,
      SuccessStoryEntity,
      TagEntity,
      UserCertificationEntity,
    ]),
  ],
  controllers: [CommunityController],
  providers: [CommunityService],
  exports: [TypeOrmModule],
})
export class CommunityModule {}
