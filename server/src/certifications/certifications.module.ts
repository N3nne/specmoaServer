import { Module } from "@nestjs/common";
import { TypeOrmModule } from "@nestjs/typeorm";

import { UsersModule } from "../users/users.module";
import { CertificationsController } from "./certifications.controller";
import { CertificationsService } from "./certifications.service";
import { CertificationEntity } from "./entities/certification.entity";
import { CertificationAcquisitionStatEntity } from "./entities/certification-acquisition-stat.entity";
import { CertificationDetailEntity } from "./entities/certification-detail.entity";
import { CertificationMajorStatEntity } from "./entities/certification-major-stat.entity";
import { CertificationPassRateStatEntity } from "./entities/certification-pass-rate-stat.entity";
import { CertificationRoundPassRateStatEntity } from "./entities/certification-round-pass-rate-stat.entity";
import { CertificationTagMappingEntity } from "./entities/certification-tag-mapping.entity";
import { ExamEligibilityEntity } from "./entities/exam-eligibility.entity";
import { ExamScheduleEntity } from "./entities/exam-schedule.entity";
import { TagEntity } from "./entities/tag.entity";
import { UserCertificationEntity } from "./entities/user-certification.entity";
import { StudySessionEntity } from "../study-sessions/entities/study-session.entity";
import { ExternalCertificationClient } from "./external/external-certification.client";
import { QnetAcquisitionStatClient } from "./external/qnet-acquisition-stat.client";
import { QnetCertificationDetailClient } from "./external/qnet-certification-detail.client";
import { QnetExamEligibilityClient } from "./external/qnet-exam-eligibility.client";
import { QnetExamScheduleClient } from "./external/qnet-exam-schedule.client";
import { QnetMajorStatClient } from "./external/qnet-major-stat.client";
import { QnetNationalQualificationClient } from "./external/qnet-national-qualification.client";
import { QnetPassRateStatClient } from "./external/qnet-pass-rate-stat.client";
import { QnetRoundPassRateStatClient } from "./external/qnet-round-pass-rate-stat.client";

@Module({
  imports: [
    TypeOrmModule.forFeature([
      CertificationEntity,
      CertificationAcquisitionStatEntity,
      CertificationDetailEntity,
      CertificationMajorStatEntity,
      CertificationPassRateStatEntity,
      CertificationRoundPassRateStatEntity,
      CertificationTagMappingEntity,
      ExamEligibilityEntity,
      ExamScheduleEntity,
      TagEntity,
      UserCertificationEntity,
      StudySessionEntity,
    ]),
    UsersModule,
  ],
  controllers: [CertificationsController],
  providers: [
    CertificationsService,
    ExternalCertificationClient,
    QnetAcquisitionStatClient,
    QnetCertificationDetailClient,
    QnetExamEligibilityClient,
    QnetExamScheduleClient,
    QnetMajorStatClient,
    QnetNationalQualificationClient,
    QnetPassRateStatClient,
    QnetRoundPassRateStatClient,
  ],
  exports: [CertificationsService],
})
export class CertificationsModule {}
