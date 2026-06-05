import { Injectable, NotFoundException } from "@nestjs/common";
import { InjectRepository } from "@nestjs/typeorm";
import { In, Repository } from "typeorm";

import { StudySessionEntity } from "../study-sessions/entities/study-session.entity";
import { UsersService } from "../users/users.service";
import { CertificationDto } from "./dto/certification.dto";
import { RegisterUserCertificationDto } from "./dto/register-user-certification.dto";
import { CertificationEntity } from "./entities/certification.entity";
import { CertificationAcquisitionStatEntity } from "./entities/certification-acquisition-stat.entity";
import { CertificationDetailEntity } from "./entities/certification-detail.entity";
import { CertificationMajorStatEntity } from "./entities/certification-major-stat.entity";
import { CertificationPassRateStatEntity } from "./entities/certification-pass-rate-stat.entity";
import { CertificationRoundPassRateStatEntity } from "./entities/certification-round-pass-rate-stat.entity";
import {
  CertificationTagMappingEntity,
  TagSource,
} from "./entities/certification-tag-mapping.entity";
import { ExamEligibilityEntity } from "./entities/exam-eligibility.entity";
import {
  ExamScheduleEntity,
  ExamScheduleType,
} from "./entities/exam-schedule.entity";
import { TagEntity, TagType } from "./entities/tag.entity";
import {
  UserCertificationEntity,
  UserCertificationStatus,
} from "./entities/user-certification.entity";
import { ExternalCertificationClient } from "./external/external-certification.client";
import { QnetAcquisitionStatClient } from "./external/qnet-acquisition-stat.client";
import { QnetCertificationDetailClient } from "./external/qnet-certification-detail.client";
import { QnetExamEligibilityClient } from "./external/qnet-exam-eligibility.client";
import {
  QnetExamScheduleClient,
  QnetExamScheduleItem,
} from "./external/qnet-exam-schedule.client";
import { QnetMajorStatClient } from "./external/qnet-major-stat.client";
import { QnetNationalQualificationClient } from "./external/qnet-national-qualification.client";
import { QnetPassRateStatClient } from "./external/qnet-pass-rate-stat.client";
import { QnetRoundPassRateStatClient } from "./external/qnet-round-pass-rate-stat.client";

@Injectable()
export class CertificationsService {
  constructor(
    @InjectRepository(CertificationEntity)
    private readonly certifications: Repository<CertificationEntity>,
    @InjectRepository(CertificationAcquisitionStatEntity)
    private readonly acquisitionStats: Repository<CertificationAcquisitionStatEntity>,
    @InjectRepository(CertificationDetailEntity)
    private readonly certificationDetails: Repository<CertificationDetailEntity>,
    @InjectRepository(CertificationMajorStatEntity)
    private readonly majorStats: Repository<CertificationMajorStatEntity>,
    @InjectRepository(CertificationPassRateStatEntity)
    private readonly passRateStats: Repository<CertificationPassRateStatEntity>,
    @InjectRepository(CertificationRoundPassRateStatEntity)
    private readonly roundPassRateStats: Repository<CertificationRoundPassRateStatEntity>,
    @InjectRepository(CertificationTagMappingEntity)
    private readonly certificationTagMappings: Repository<CertificationTagMappingEntity>,
    @InjectRepository(ExamEligibilityEntity)
    private readonly examEligibilities: Repository<ExamEligibilityEntity>,
    @InjectRepository(ExamScheduleEntity)
    private readonly schedules: Repository<ExamScheduleEntity>,
    @InjectRepository(UserCertificationEntity)
    private readonly userCertifications: Repository<UserCertificationEntity>,
    @InjectRepository(StudySessionEntity)
    private readonly studySessions: Repository<StudySessionEntity>,
    @InjectRepository(TagEntity)
    private readonly tags: Repository<TagEntity>,
    private readonly externalClient: ExternalCertificationClient,
    private readonly qnetAcquisitionStatClient: QnetAcquisitionStatClient,
    private readonly qnetCertificationDetailClient: QnetCertificationDetailClient,
    private readonly qnetExamEligibilityClient: QnetExamEligibilityClient,
    private readonly qnetExamScheduleClient: QnetExamScheduleClient,
    private readonly qnetMajorStatClient: QnetMajorStatClient,
    private readonly qnetNationalQualificationClient: QnetNationalQualificationClient,
    private readonly qnetPassRateStatClient: QnetPassRateStatClient,
    private readonly qnetRoundPassRateStatClient: QnetRoundPassRateStatClient,
    private readonly users: UsersService,
  ) {}

  async findAll() {
    const rows = await this.certifications.find({ order: { name: "ASC" } });
    return rows.map(CertificationDto.fromEntity);
  }

  async search(params: {
    q?: string;
    tagId?: string;
    sort?: string;
    qualificationType?: string;
    limit?: number;
  }) {
    const q = params.q?.trim();
    const limit = Math.min(Math.max(params.limit ?? 10, 1), 30);
    const sort = params.sort === "name" ? "name" : "popular";

    const query = this.certifications
      .createQueryBuilder("certification")
      .leftJoin("certification.tagMappings", "tagMapping")
      .leftJoin("tagMapping.tag", "tag")
      .leftJoin(
        CertificationRoundPassRateStatEntity,
        "stat",
        'stat."certificationId" = certification.id',
      )
      .leftJoin(
        (subQuery) =>
          subQuery
            .select('major."jmName"', "name")
            .addSelect(
              'sum(major."accumulatedAcquiredCount")::int',
              "acquiredCount",
            )
            .from(CertificationMajorStatEntity, "major")
            .where(
              'major."baseYear" = (select max(latest."baseYear") from certification_major_stats latest)',
            )
            .groupBy('major."jmName"'),
        "acquired",
        "acquired.name = certification.name",
      )
      .select("certification.id", "id")
      .addSelect("certification.name", "name")
      .addSelect("certification.category", "category")
      .addSelect("certification.organization", "organization")
      .addSelect('coalesce(sum(stat."examineeCount"), 0)::int', "examineeCount")
      .addSelect('coalesce(acquired."acquiredCount", 0)::int', "acquiredCount")
      .groupBy("certification.id")
      .addGroupBy("certification.name")
      .addGroupBy("certification.category")
      .addGroupBy("certification.organization")
      .addGroupBy('acquired."acquiredCount"')
      .limit(limit);

    if (q) {
      query.andWhere(
        [
          "certification.name ILIKE :q",
          "certification.category ILIKE :q",
          "certification.organization ILIKE :q",
          "tag.name ILIKE :q",
        ].join(" OR "),
        { q: `%${q}%` },
      );
    }

    if (params.tagId) {
      query.andWhere(
        `exists (
          select 1
          from certification_tag_mappings selected_mapping
          where selected_mapping."certificationId" = certification.id
            and selected_mapping."tagId" = :tagId
        )`,
        { tagId: params.tagId },
      );
    }

    const qualificationTypeName = this.toQualificationTypeName(
      params.qualificationType,
    );
    if (qualificationTypeName) {
      query.andWhere(
        `exists (
          select 1
          from certification_tag_mappings qualification_mapping
          inner join tags qualification_tag
            on qualification_tag.id = qualification_mapping."tagId"
          where qualification_mapping."certificationId" = certification.id
            and qualification_tag.type = :qualificationTagType
            and qualification_tag.name = :qualificationTypeName
        )`,
        {
          qualificationTagType: TagType.QUALIFICATION_TYPE,
          qualificationTypeName,
        },
      );
    }

    if (sort === "name") {
      query.orderBy("certification.name", "ASC");
    } else {
      query.orderBy('coalesce(sum(stat."examineeCount"), 0)', "DESC");
      query.addOrderBy("certification.name", "ASC");
    }

    const rows = await query.getRawMany<{
      id: string;
      name: string;
      category: string;
      organization?: string;
      examineeCount: number;
      acquiredCount: number;
    }>();
    const tagMap = await this.loadTagSummaries(rows.map((row) => row.id));

    return rows.map((row) => ({
      id: row.id,
      name: row.name,
      category: row.category,
      organization: row.organization,
      examineeCount: Number(row.examineeCount ?? 0),
      acquiredCount: Number(row.acquiredCount ?? 0),
      tags: tagMap.get(row.id) ?? [],
    }));
  }

  async findSearchTags(limit = 18, qualificationType?: string, q?: string) {
    const safeLimit = Math.min(Math.max(limit, 1), 30);
    const qualificationTypeName =
      this.toQualificationTypeName(qualificationType);
    const keyword = q?.trim();
    const query = this.tags
      .createQueryBuilder("tag")
      .innerJoin("tag.certificationMappings", "mapping")
      .select("tag.id", "id")
      .addSelect("tag.name", "name")
      .addSelect("tag.type", "type")
      .addSelect("count(mapping.id)::int", "certificationCount")
      .where("tag.type in (:...types)", {
        types: [TagType.FIELD, TagType.SUBFIELD, TagType.KEYWORD],
      })
      .groupBy("tag.id")
      .addGroupBy("tag.name")
      .addGroupBy("tag.type")
      .orderBy("count(mapping.id)", "DESC")
      .addOrderBy("tag.name", "ASC")
      .limit(safeLimit);

    if (keyword) {
      query.andWhere("tag.name ILIKE :tagKeyword", {
        tagKeyword: `%${keyword}%`,
      });
    }

    if (qualificationTypeName) {
      query.andWhere(
        `exists (
          select 1
          from certification_tag_mappings qualification_mapping
          inner join tags qualification_tag
            on qualification_tag.id = qualification_mapping."tagId"
          where qualification_mapping."certificationId" = mapping."certificationId"
            and qualification_tag.type = :qualificationTagType
            and qualification_tag.name = :qualificationTypeName
        )`,
        {
          qualificationTagType: TagType.QUALIFICATION_TYPE,
          qualificationTypeName,
        },
      );
    }

    const rows = await query.getRawMany<{
      id: string;
      name: string;
      type: TagType;
      certificationCount: number;
    }>();

    return rows.map((row) => ({
      id: row.id,
      name: row.name,
      type: row.type,
      certificationCount: Number(row.certificationCount ?? 0),
    }));
  }

  async getRankings(params: {
    metric?: string;
    qualificationType?: string;
    tagId?: string;
    limit?: number;
  }) {
    const metric = params.metric ?? "popular";
    const limit = Math.min(Math.max(params.limit ?? 30, 1), 100);

    if (metric === "age") {
      return this.getAgeRankings(limit);
    }
    if (metric === "major") {
      return this.getMajorRankings(limit, params.qualificationType);
    }
    if (metric === "pass_rate") {
      return this.getPassRateRankings(limit, params.qualificationType);
    }

    return this.getPopularityRankings(
      limit,
      params.qualificationType,
      params.tagId,
      metric === "field",
    );
  }

  private async getPopularityRankings(
    limit: number,
    qualificationType?: string,
    tagId?: string,
    includeFieldLabel = false,
  ) {
    const query = this.certifications
      .createQueryBuilder("certification")
      .leftJoin(
        CertificationRoundPassRateStatEntity,
        "stat",
        'stat."certificationId" = certification.id',
      )
      .select("certification.id", "id")
      .addSelect("certification.name", "name")
      .addSelect("certification.category", "category")
      .addSelect("certification.organization", "organization")
      .addSelect('coalesce(sum(stat."examineeCount"), 0)::int', "primaryCount")
      .addSelect('coalesce(sum(stat."passCount"), 0)::int', "passCount")
      .addSelect(
        `case
          when coalesce(sum(stat."examineeCount"), 0) > 0
          then round((sum(stat."passCount")::numeric / sum(stat."examineeCount")) * 100, 1)
          else 0
        end`,
        "passRate",
      )
      .where("stat.id is not null")
      .groupBy("certification.id")
      .addGroupBy("certification.name")
      .addGroupBy("certification.category")
      .addGroupBy("certification.organization")
      .orderBy('coalesce(sum(stat."examineeCount"), 0)', "DESC")
      .limit(limit);

    this.applyQualificationFilter(query, qualificationType);
    this.applyTagFilter(query, tagId);

    const rows = await query.getRawMany<RankingRawRow>();
    const tagMap = includeFieldLabel
      ? await this.loadTagSummaries(rows.map((row) => row.id).filter(Boolean))
      : new Map<string, { id: string; name: string; type: TagType }[]>();

    return rows.map((row, index) =>
      this.toRankingItem(
        row,
        index,
        includeFieldLabel ? tagMap.get(row.id)?.[0]?.name : undefined,
      ),
    );
  }

  private async getMajorRankings(limit: number, qualificationType?: string) {
    const query = this.certifications
      .createQueryBuilder("certification")
      .innerJoin(
        CertificationMajorStatEntity,
        "major",
        'major."jmCd" = certification."externalId"',
      )
      .select("certification.id", "id")
      .addSelect("certification.name", "name")
      .addSelect("certification.category", "category")
      .addSelect("certification.organization", "organization")
      .addSelect(
        'coalesce(sum(major."accumulatedAcquiredCount"), 0)::int',
        "primaryCount",
      )
      .addSelect('max(major."middleFieldName")', "metaLabel")
      .groupBy("certification.id")
      .addGroupBy("certification.name")
      .addGroupBy("certification.category")
      .addGroupBy("certification.organization")
      .orderBy('coalesce(sum(major."accumulatedAcquiredCount"), 0)', "DESC")
      .limit(limit);

    this.applyQualificationFilter(query, qualificationType);

    const rows = await query.getRawMany<RankingRawRow>();
    return rows.map((row, index) => this.toRankingItem(row, index));
  }

  private async getPassRateRankings(limit: number, qualificationType?: string) {
    const query = this.certifications
      .createQueryBuilder("certification")
      .innerJoin(
        CertificationRoundPassRateStatEntity,
        "stat",
        'stat."certificationId" = certification.id',
      )
      .select("certification.id", "id")
      .addSelect("certification.name", "name")
      .addSelect("certification.category", "category")
      .addSelect("certification.organization", "organization")
      .addSelect('coalesce(sum(stat."examineeCount"), 0)::int', "primaryCount")
      .addSelect('coalesce(sum(stat."passCount"), 0)::int', "passCount")
      .addSelect(
        `round((sum(stat."passCount")::numeric / nullif(sum(stat."examineeCount"), 0)) * 100, 1)`,
        "passRate",
      )
      .groupBy("certification.id")
      .addGroupBy("certification.name")
      .addGroupBy("certification.category")
      .addGroupBy("certification.organization")
      .having('coalesce(sum(stat."examineeCount"), 0) >= 50')
      .orderBy(
        'sum(stat."passCount")::numeric / nullif(sum(stat."examineeCount"), 0)',
        "DESC",
      )
      .addOrderBy('coalesce(sum(stat."examineeCount"), 0)', "DESC")
      .limit(limit);

    this.applyQualificationFilter(query, qualificationType);

    const rows = await query.getRawMany<RankingRawRow>();
    return rows.map((row, index) => this.toRankingItem(row, index));
  }

  private async getAgeRankings(limit: number) {
    const rows = await this.acquisitionStats
      .createQueryBuilder("stat")
      .select("stat.id", "id")
      .addSelect('stat."reportGroupName"', "name")
      .addSelect('stat."reportGroup"', "category")
      .addSelect('stat."totalCount"', "primaryCount")
      .addSelect('stat."issuedCount"', "passCount")
      .where('stat."reportGroup" = :group', { group: "연령별" })
      .orderBy('stat."totalCount"', "DESC")
      .limit(limit)
      .getRawMany<RankingRawRow>();

    return rows.map((row, index) =>
      this.toRankingItem(row, index, "취득 현황"),
    );
  }

  private applyQualificationFilter(query: any, qualificationType?: string) {
    const qualificationTypeName =
      this.toQualificationTypeName(qualificationType);
    if (!qualificationTypeName) {
      return;
    }

    query.andWhere(
      `exists (
        select 1
        from certification_tag_mappings qualification_mapping
        inner join tags qualification_tag
          on qualification_tag.id = qualification_mapping."tagId"
        where qualification_mapping."certificationId" = certification.id
          and qualification_tag.type = :rankingQualificationTagType
          and qualification_tag.name = :rankingQualificationTypeName
      )`,
      {
        rankingQualificationTagType: TagType.QUALIFICATION_TYPE,
        rankingQualificationTypeName: qualificationTypeName,
      },
    );
  }

  private applyTagFilter(query: any, tagId?: string) {
    if (!tagId) {
      return;
    }

    query.andWhere(
      `exists (
        select 1
        from certification_tag_mappings selected_mapping
        where selected_mapping."certificationId" = certification.id
          and selected_mapping."tagId" = :rankingTagId
      )`,
      { rankingTagId: tagId },
    );
  }

  private toRankingItem(row: RankingRawRow, index: number, metaLabel?: string) {
    const passRate =
      row.passRate === undefined || row.passRate === null
        ? undefined
        : Number(row.passRate);

    return {
      rank: index + 1,
      id: row.id,
      name: row.name,
      category: row.category,
      organization: row.organization,
      primaryCount: Number(row.primaryCount ?? 0),
      passCount: Number(row.passCount ?? 0),
      passRate,
      metaLabel: metaLabel ?? row.metaLabel,
    };
  }

  private toQualificationTypeName(value?: string) {
    if (value === "national_technical") {
      return "국가기술자격";
    }
    if (value === "professional") {
      return "국가전문자격";
    }
    if (value === "national_technical") {
      return "국가기술자격";
    }
    if (value === "professional") {
      return "국가전문자격";
    }
    return undefined;
  }

  async findOne(id: string) {
    const certification = await this.certifications.findOne({
      where: { id },
      relations: { schedules: true, details: true },
    });

    if (!certification) {
      throw new NotFoundException(`Certification ${id} was not found.`);
    }

    return {
      ...CertificationDto.fromEntity(certification),
      schedules: certification.schedules.map((schedule) => ({
        id: schedule.id,
        type: schedule.type,
        title: schedule.title,
        startsOn: schedule.startsOn,
        endsOn: schedule.endsOn,
        source: schedule.source,
      })),
      details: certification.details.map((detail) => ({
        id: detail.id,
        infoType: detail.infoType,
        contents: detail.contents,
      })),
    };
  }

  private async loadTagSummaries(certificationIds: string[]) {
    const map = new Map<
      string,
      { id: string; name: string; type: TagType }[]
    >();
    if (certificationIds.length === 0) {
      return map;
    }

    const mappings = await this.certificationTagMappings.find({
      where: { certification: { id: In(certificationIds) } },
      relations: { certification: true, tag: true },
      order: { confidence: "DESC" },
    });

    for (const mapping of mappings) {
      const list = map.get(mapping.certification.id) ?? [];
      if (list.length < 4) {
        list.push({
          id: mapping.tag.id,
          name: mapping.tag.name,
          type: mapping.tag.type,
        });
      }
      map.set(mapping.certification.id, list);
    }

    return map;
  }

  async findDetailPage(id: string) {
    const certification = await this.certifications.findOne({
      where: { id },
      relations: { details: true },
    });

    if (!certification) {
      throw new NotFoundException(`Certification ${id} was not found.`);
    }

    let externalDetailError: string | undefined;
    let externalScheduleError: string | undefined;

    let schedules = await this.schedules.find({
      where: { certification: { id: certification.id } },
      order: { startsOn: "ASC", type: "ASC" },
    });

    if (schedules.length === 0 && certification.externalId) {
      try {
        await this.syncQnetExamScheduleByCertification(certification);
        schedules = await this.schedules.find({
          where: { certification: { id: certification.id } },
          order: { startsOn: "ASC", type: "ASC" },
        });
      } catch (error) {
        externalScheduleError =
          error instanceof Error ? error.message : String(error);
      }
    }

    if (schedules.length === 0) {
      schedules = await this.findSharedSchedulesByGrade(certification);
    }
    schedules = this.dedupeSchedules(schedules);

    if (certification.details.length === 0) {
      try {
        await this.syncQnetCertificationDetailByCertification(certification);
      } catch (error) {
        externalDetailError =
          error instanceof Error ? error.message : String(error);
      }
      certification.details = await this.certificationDetails.find({
        where: { certification: { id: certification.id } },
        relations: { certification: true },
        order: { infoType: "ASC" },
      });
    }

    const details = certification.details.map((detail) => ({
      id: detail.id,
      infoType: detail.infoType,
      contents: this.cleanDetailContents(detail.contents),
    }));
    const eligibility = await this.buildEligibilityContents(
      certification,
      details,
    );

    return {
      id: certification.id,
      name: certification.name,
      category: certification.category,
      description: this.buildCertificationDescription(certification, details),
      ...(false
        ? {
            legacyEligibility:
              this.findDetailContents(details, ["응시자격"]) ??
              "공공데이터에서 별도의 응시자격 항목을 제공하지 않았습니다. 상세 자격 제한은 Q-Net 공고 기준으로 확인이 필요합니다.",
          }
        : {}),
      eligibility,
      examSubjects: this.findDetailContents(details, [
        "시험과목 및 배점",
        "시험과목",
        "취득방법",
        "출제기준",
        "출제경향",
      ]),
      details,
      schedules: schedules.map((schedule) => ({
        id: schedule.id,
        type: schedule.type,
        title: schedule.title,
        startsOn: schedule.startsOn,
        endsOn: schedule.endsOn,
        source: schedule.source,
      })),
      fetchedFromExternal: certification.details.length > 0,
      externalDetailError,
      externalScheduleError,
    };
  }

  async registerForUser(
    userId: string | undefined,
    dto: RegisterUserCertificationDto,
  ) {
    const user = await this.users.getRequestUser(userId);
    const certification = await this.certifications.findOneBy({
      id: dto.certificationId,
    });

    if (!certification) {
      throw new NotFoundException(
        `Certification ${dto.certificationId} was not found.`,
      );
    }

    const existing = await this.userCertifications.findOne({
      where: {
        user: { id: user.id },
        certification: { id: certification.id },
      },
      relations: { user: true, certification: true },
    });
    const target =
      existing ?? this.userCertifications.create({ user, certification });

    target.status =
      dto.status ?? target.status ?? UserCertificationStatus.PLANNED;
    target.progress = dto.progress ?? target.progress ?? 0;
    target.targetExamDate = dto.targetExamDate ?? target.targetExamDate;
    target.certifiedOn = dto.certifiedOn ?? target.certifiedOn;
    target.certificateNumber =
      dto.certificateNumber ?? target.certificateNumber;
    target.preparationCategory =
      dto.preparationCategory ?? target.preparationCategory;
    target.notes = dto.notes ?? target.notes;

    const saved = await this.userCertifications.save(target);
    return {
      id: saved.id,
      certificationId: certification.id,
      status: saved.status,
      progress: saved.progress,
      targetExamDate: saved.targetExamDate,
      certifiedOn: saved.certifiedOn,
      certificateNumber: saved.certificateNumber,
      preparationCategory: saved.preparationCategory,
      notes: saved.notes,
    };
  }

  async findForUser(userId: string | undefined) {
    const user = await this.users.getRequestUser(userId);
    const rows = await this.userCertifications.find({
      where: { user: { id: user.id } },
      relations: { certification: true },
      order: { createdAt: "DESC" },
    });

    return {
      totalCount: rows.length,
      items: rows.map((row) => ({
        id: row.id,
        status: row.status,
        progress: row.progress,
        targetExamDate: row.targetExamDate,
        certifiedOn: row.certifiedOn,
        certificateNumber: row.certificateNumber,
        preparationCategory: row.preparationCategory,
        notes: row.notes,
        certification: {
          id: row.certification.id,
          name: row.certification.name,
          category: row.certification.category,
          organization: row.certification.organization,
        },
      })),
    };
  }

  async removeForUser(userId: string | undefined, userCertificationId: string) {
    const user = await this.users.getRequestUser(userId);
    const row = await this.userCertifications.findOne({
      where: {
        id: userCertificationId,
        user: { id: user.id },
      },
      relations: { user: true, certification: true },
    });

    if (!row) {
      throw new NotFoundException(
        `User certification ${userCertificationId} was not found.`,
      );
    }

    await this.studySessions
      .createQueryBuilder()
      .delete()
      .from(StudySessionEntity)
      .where('"userId" = :userId', { userId: user.id })
      .andWhere('"certificationId" = :certificationId', {
        certificationId: row.certification.id,
      })
      .execute();
    await this.userCertifications.remove(row);
    return { id: userCertificationId, deleted: true };
  }

  async syncFromExternalApi() {
    const incoming = await this.externalClient.fetchCertifications();
    let certificationCount = 0;
    let scheduleCount = 0;

    for (const item of incoming) {
      const certification = await this.certifications.save(
        this.certifications.create({
          ...(await this.certifications.findOneBy({
            externalSource: item.externalSource,
            externalId: item.externalId,
          })),
          externalSource: item.externalSource,
          externalId: item.externalId,
          name: item.name,
          englishName: item.englishName,
          category: item.category,
          organization: item.organization,
          description: item.description,
          officialUrl: item.officialUrl,
          rawPayload: item.rawPayload ?? {},
        }),
      );
      certificationCount += 1;

      for (const schedule of item.schedules ?? []) {
        await this.schedules.save(
          this.schedules.create({
            certification,
            type: schedule.type as ExamScheduleType,
            title: schedule.title,
            startsOn: schedule.startsOn,
            endsOn: schedule.endsOn,
            rawPayload: schedule.rawPayload ?? {},
          }),
        );
        scheduleCount += 1;
      }
    }

    return { certificationCount, scheduleCount };
  }

  async syncQnetNationalQualificationList() {
    const { totalCount, items } =
      await this.qnetNationalQualificationClient.fetchList();
    let syncedCount = 0;

    for (const item of items) {
      await this.certifications.save(
        this.certifications.create({
          ...(await this.certifications.findOneBy({
            externalSource: "qnet-national-qualification-list",
            externalId: item.jmcd,
          })),
          externalSource: "qnet-national-qualification-list",
          externalId: item.jmcd,
          name: item.jmfldnm,
          category:
            item.mdobligfldnm ?? item.obligfldnm ?? item.seriesnm ?? "국가자격",
          organization: "한국산업인력공단",
          description: [
            item.qualgbnm,
            item.seriesnm,
            item.obligfldnm,
            item.mdobligfldnm,
          ]
            .filter(Boolean)
            .join(" / "),
          rawPayload: item,
        }),
      );
      syncedCount += 1;
    }

    return {
      source: "qnet-national-qualification-list",
      totalCount,
      syncedCount,
    };
  }

  async syncQnetCertificationDetails(limit?: number) {
    const take = limit && limit > 0 ? limit : 25;
    const rows = await this.certifications.find({
      where: { externalSource: "qnet-national-qualification-list" },
      order: { name: "ASC" },
      take,
    });
    let certificationCount = 0;
    let detailCount = 0;

    for (const certification of rows) {
      detailCount +=
        await this.syncQnetCertificationDetailByCertification(certification);
      certificationCount += 1;
    }

    return {
      source: "qnet-certification-detail",
      certificationCount,
      detailCount,
      limit: take,
    };
  }

  private async syncQnetCertificationDetailByCertification(
    certification: CertificationEntity,
  ) {
    const { items } = await this.qnetCertificationDetailClient.fetchByJmCd(
      certification.externalId,
    );
    let detailCount = 0;

    for (const item of items) {
      await this.certificationDetails.save(
        this.certificationDetails.create({
          ...(await this.certificationDetails.findOne({
            where: {
              certification: { id: certification.id },
              infoType: item.infogb,
            },
            relations: { certification: true },
          })),
          certification,
          infoType: item.infogb,
          contents: item.contents,
          majorFieldCode: item.obligfldcd,
          majorFieldName: item.obligfldnm,
          middleFieldCode: item.mdobligfldcd,
          middleFieldName: item.mdobligfldnm,
          rawPayload: item,
        }),
      );
      detailCount += 1;
    }

    return detailCount;
  }

  private async buildEligibilityContents(
    certification: CertificationEntity,
    details: Array<{ infoType: string; contents: string }>,
  ) {
    const detailEligibility = this.findDetailContents(details, ["응시자격"]);
    const gradeNames = this.getCertificationGradeNames(certification);
    const gradeEligibilityRows =
      gradeNames.length === 0
        ? []
        : await this.examEligibilities.find({
            where: { gradeName: In(gradeNames) },
            order: { eligibilityCode: "ASC" },
          });
    const gradeEligibility = gradeEligibilityRows.map(
      (row) => row.eligibilityName,
    );
    const sections: string[] = [];

    if (detailEligibility) {
      sections.push(detailEligibility);
    }

    if (gradeEligibility.length > 0) {
      sections.push(
        [
          `${gradeNames.join(", ")} 등급 공통 응시자격`,
          ...gradeEligibility.map((item, index) => `${index + 1}. ${item}`),
        ].join("\n"),
      );
    }

    if (sections.length > 0) {
      return sections.join("\n\n");
    }

    return "공공데이터에서 별도의 응시자격 항목을 제공하지 않았습니다. 상세 자격 제한은 Q-Net 공고 기준으로 확인이 필요합니다.";
  }

  private getCertificationGradeNames(certification: CertificationEntity) {
    const rawPayload = certification.rawPayload ?? {};
    const candidates = [
      rawPayload.seriesnm,
      rawPayload.grdNm,
      rawPayload.gradeName,
      certification.name,
    ]
      .map((value) => (value == null ? "" : String(value)))
      .filter(Boolean);
    const grades = [
      "기술사",
      "기능장",
      "기사",
      "산업기사",
      "기능사",
      "1급",
      "2급",
      "단일등급",
    ];
    const result = new Set<string>();

    for (const candidate of candidates) {
      for (const grade of grades) {
        if (candidate.includes(grade)) {
          if (grade === "기사" && candidate.includes("산업기사")) {
            continue;
          }

          result.add(grade);
        }
      }
    }

    return [...result];
  }

  private buildCertificationDescription(
    certification: CertificationEntity,
    details: Array<{ infoType: string; contents: string }>,
  ) {
    const overview = this.findDetailContents(details, [
      "개요",
      "자격정보",
      "기본정보",
      "출제경향",
      "취득방법",
    ]);

    if (overview) {
      return overview;
    }

    if (certification.description) {
      return certification.description;
    }

    return `${certification.name} 자격증 상세 정보입니다.`;
  }

  private findDetailContents(
    details: Array<{ infoType: string; contents: string }>,
    infoTypes: string[],
  ) {
    for (const type of infoTypes) {
      const detail = details.find((row) => row.infoType.includes(type));

      if (detail?.contents) {
        return detail.contents;
      }
    }

    return undefined;
  }

  private cleanDetailContents(contents: string) {
    return contents
      .replace(/<style[\s\S]*?<\/style>/gi, " ")
      .replace(/<script[\s\S]*?<\/script>/gi, " ")
      .replace(/BODY\s*\{[\s\S]*?\}\s*/gi, " ")
      .replace(/[A-Z][A-Z0-9.-]*\s*\{[^}]*\}/g, " ")
      .replace(/<br\s*\/?>/gi, "\n")
      .replace(/<\/(p|div|li|tr|table|ul|ol|h[1-6])>/gi, "\n")
      .replace(/<[^>]+>/g, " ")
      .replace(/&nbsp;/gi, " ")
      .replace(/&amp;/gi, "&")
      .replace(/&lt;/gi, "<")
      .replace(/&gt;/gi, ">")
      .replace(/&#(\d+);/g, (_, code: string) =>
        String.fromCharCode(Number(code)),
      )
      .replace(/&middot;/gi, "·")
      .replace(/\r/g, "")
      .replace(/[ \t]+/g, " ")
      .replace(/\n\s+/g, "\n")
      .replace(/\n{3,}/g, "\n\n")
      .trim();
  }

  async syncQnetExamSchedules(limit?: number) {
    const take = limit && limit > 0 ? limit : 25;
    const rows = await this.certifications.find({
      where: { externalSource: "qnet-national-qualification-list" },
      order: { name: "ASC" },
      take,
    });
    let certificationCount = 0;
    let scheduleCount = 0;

    for (const certification of rows) {
      const { items } = await this.qnetExamScheduleClient.fetchByJmCd(
        certification.externalId,
      );

      for (const item of items) {
        const schedules = this.mapQnetScheduleItem(certification, item);

        for (const schedule of schedules) {
          await this.schedules.save(
            this.schedules.create({
              ...(await this.schedules.findOneBy({
                externalSource: schedule.externalSource,
                externalId: schedule.externalId,
              })),
              ...schedule,
            }),
          );
          scheduleCount += 1;
        }
      }

      certificationCount += 1;
    }

    return {
      source: "qnet-exam-schedule",
      certificationCount,
      scheduleCount,
      limit: take,
    };
  }

  async syncQnetExamScheduleForCertification(id: string) {
    const certification = await this.certifications.findOneBy({ id });

    if (!certification) {
      throw new NotFoundException(`Certification ${id} was not found.`);
    }

    const scheduleCount =
      await this.syncQnetExamScheduleByCertification(certification);

    return {
      source: "qnet-exam-schedule",
      certificationId: certification.id,
      certificationName: certification.name,
      scheduleCount,
    };
  }

  private async syncQnetExamScheduleByCertification(
    certification: CertificationEntity,
  ) {
    if (!certification.externalId) {
      return 0;
    }

    const { items } = await this.qnetExamScheduleClient.fetchByJmCd(
      certification.externalId,
    );
    let scheduleCount = 0;

    for (const item of items) {
      const schedules = this.mapQnetScheduleItem(certification, item);

      for (const schedule of schedules) {
        await this.schedules.save(
          this.schedules.create({
            ...(await this.schedules.findOneBy({
              externalSource: schedule.externalSource,
              externalId: schedule.externalId,
            })),
            ...schedule,
          }),
        );
        scheduleCount += 1;
      }
    }

    return scheduleCount;
  }

  private async findSharedSchedulesByGrade(certification: CertificationEntity) {
    const scheduleKeyword = this.scheduleKeywordForCertification(
      certification.name,
    );

    if (!scheduleKeyword) {
      return [];
    }

    return this.schedules
      .createQueryBuilder("schedule")
      .where("schedule.title ILIKE :keyword", {
        keyword: `%${scheduleKeyword}%`,
      })
      .orderBy("schedule.startsOn", "ASC")
      .addOrderBy("schedule.type", "ASC")
      .getMany();
  }

  private dedupeSchedules(schedules: ExamScheduleEntity[]) {
    const seen = new Set<string>();
    const result: ExamScheduleEntity[] = [];

    for (const schedule of schedules) {
      const key = [
        schedule.type,
        schedule.title,
        schedule.startsOn,
        schedule.endsOn ?? "",
      ].join("|");

      if (seen.has(key)) {
        continue;
      }

      seen.add(key);
      result.push(schedule);
    }

    return result;
  }

  private scheduleKeywordForCertification(name: string) {
    if (name.includes("기능사")) {
      return "정기 기능사";
    }
    if (name.includes("산업기사") || name.includes("기사")) {
      return "정기 기사";
    }
    if (name.includes("기능장")) {
      return "정기 기능장";
    }
    if (name.includes("기술사")) {
      return "정기 기술사";
    }
    return undefined;
  }

  private mapQnetScheduleItem(
    certification: CertificationEntity,
    item: QnetExamScheduleItem,
  ): Array<Partial<ExamScheduleEntity>> {
    const source = "qnet-exam-schedule";
    const planName = item.implplannm;
    const baseId = `${certification.externalId}:${planName}`;
    const rawPayload = item;

    return [
      this.createScheduleEvent({
        certification,
        source,
        externalSource: source,
        externalId: `${baseId}:doc-registration`,
        type: ExamScheduleType.REGISTRATION,
        title: `${planName} 필기 원서접수`,
        startsOn: this.toIsoDate(item.docregstartdt),
        endsOn: this.toIsoDate(item.docregenddt),
        rawPayload,
      }),
      this.createScheduleEvent({
        certification,
        source,
        externalSource: source,
        externalId: `${baseId}:written`,
        type: ExamScheduleType.WRITTEN,
        title: `${planName} 필기시험`,
        startsOn: this.toIsoDate(item.docexamstartdt),
        endsOn: this.toIsoDate(item.docexamenddt),
        rawPayload,
      }),
      this.createScheduleEvent({
        certification,
        source,
        externalSource: source,
        externalId: `${baseId}:written-result`,
        type: ExamScheduleType.RESULT,
        title: `${planName} 필기 합격자 발표`,
        startsOn: this.toIsoDate(item.docpassdt),
        rawPayload,
      }),
      this.createScheduleEvent({
        certification,
        source,
        externalSource: source,
        externalId: `${baseId}:doc-submit`,
        type: ExamScheduleType.CUSTOM,
        title: `${planName} 응시자격 서류제출`,
        startsOn: this.toIsoDate(item.docsubmitstartdt),
        endsOn: this.toIsoDate(item.docsubmitenddt),
        rawPayload,
      }),
      this.createScheduleEvent({
        certification,
        source,
        externalSource: source,
        externalId: `${baseId}:practical-registration`,
        type: ExamScheduleType.REGISTRATION,
        title: `${planName} 실기 원서접수`,
        startsOn: this.toIsoDate(item.pracregstartdt),
        endsOn: this.toIsoDate(item.pracregenddt),
        rawPayload,
      }),
      this.createScheduleEvent({
        certification,
        source,
        externalSource: source,
        externalId: `${baseId}:practical`,
        type: ExamScheduleType.PRACTICAL,
        title: `${planName} 실기시험`,
        startsOn: this.toIsoDate(item.pracexamstartdt),
        endsOn: this.toIsoDate(item.pracexamenddt),
        rawPayload,
      }),
      this.createScheduleEvent({
        certification,
        source,
        externalSource: source,
        externalId: `${baseId}:practical-result`,
        type: ExamScheduleType.RESULT,
        title: `${planName} 실기 합격자 발표`,
        startsOn: this.toIsoDate(item.pracpassstartdt),
        endsOn: this.toIsoDate(item.pracpassenddt),
        rawPayload,
      }),
    ].filter((schedule): schedule is Partial<ExamScheduleEntity> =>
      Boolean(schedule),
    );
  }

  private createScheduleEvent(input: Partial<ExamScheduleEntity>) {
    if (!input.startsOn) {
      return undefined;
    }

    return input;
  }

  private toIsoDate(value?: number | string) {
    if (!value) {
      return undefined;
    }

    const text = String(value).replace(/\D/g, "");

    if (text.length !== 8) {
      return undefined;
    }

    return `${text.slice(0, 4)}-${text.slice(4, 6)}-${text.slice(6, 8)}`;
  }

  async syncQnetExamEligibilities() {
    const source = "qnet-exam-eligibility";
    const numOfRows = 100;
    let pageNo = 1;
    let totalCount = 0;
    let syncedCount = 0;

    do {
      const page = await this.qnetExamEligibilityClient.fetchPage(
        pageNo,
        numOfRows,
      );
      totalCount = page.totalCount;

      for (const item of page.items) {
        await this.examEligibilities.save(
          this.examEligibilities.create({
            ...(await this.examEligibilities.findOneBy({
              externalSource: source,
              externalId: item.emqualCd,
            })),
            externalSource: source,
            externalId: item.emqualCd,
            eligibilityCode: item.emqualCd,
            eligibilityName: item.emqualDispNm,
            gradeCode: String(item.grdCd),
            gradeName: item.grdNm,
            qualificationTypeCode: item.qualgbCd,
            qualificationTypeName: item.qualgbNm,
            rawPayload: item,
          }),
        );
        syncedCount += 1;
      }

      pageNo += 1;
    } while ((pageNo - 1) * numOfRows < totalCount);

    return {
      source,
      totalCount,
      syncedCount,
    };
  }

  async syncQnetAcquisitionStats(baseYear: number) {
    const source = "qnet-acquisition-stat";
    const { totalCount, items } =
      await this.qnetAcquisitionStatClient.fetchByBaseYear(baseYear);
    let syncedCount = 0;

    for (const item of items) {
      const issuedCount = this.toInteger(item.givecnt);
      const notIssuedCount = this.toInteger(item.giveNotcnt);
      const implementationYear = this.toInteger(item.implYy);
      const externalId = `${baseYear}:${implementationYear}:${item.reportGb}:${item.reportGbCdNm}`;

      await this.acquisitionStats.save(
        this.acquisitionStats.create({
          ...(await this.acquisitionStats.findOneBy({
            externalSource: source,
            externalId,
          })),
          externalSource: source,
          externalId,
          baseYear,
          implementationYear,
          reportGroup: item.reportGb,
          reportGroupName: item.reportGbCdNm,
          issuedCount,
          notIssuedCount,
          totalCount: issuedCount + notIssuedCount,
          rawPayload: item,
        }),
      );
      syncedCount += 1;
    }

    return {
      source,
      baseYear,
      totalCount,
      syncedCount,
    };
  }

  async syncQnetMajorStats(baseYear: number) {
    const source = "qnet-major-stat";
    const numOfRows = 100;
    let pageNo = 1;
    let totalCount = 0;
    let syncedCount = 0;

    do {
      const page = await this.qnetMajorStatClient.fetchPage(
        baseYear,
        pageNo,
        numOfRows,
      );
      totalCount = page.totalCount;

      for (const item of page.items) {
        const jmCd = String(item.jmCd);
        const gradeCode = String(item.grdCd);
        const externalId = `${baseYear}:${jmCd}:${gradeCode}:${item.mjrYnCcd}`;

        await this.majorStats.save(
          this.majorStats.create({
            ...(await this.majorStats.findOneBy({
              externalSource: source,
              externalId,
            })),
            externalSource: source,
            externalId,
            baseYear,
            jmCd,
            jmName: item.jmNm,
            gradeCode,
            gradeName: item.grdNm,
            middleFieldCode:
              item.mdobligFldCd == null ? undefined : String(item.mdobligFldCd),
            middleFieldName: item.mdobligFldNm,
            majorYnCode: item.mjrYnCcd,
            accumulatedAcquiredCount: this.toInteger(item.accumAcquCnt),
            year1AcquiredCount: this.toInteger(item.yy1AcquCnt),
            year2AcquiredCount: this.toInteger(item.yy2AcquCnt),
            year3AcquiredCount: this.toInteger(item.yy3AcquCnt),
            year4AcquiredCount: this.toInteger(item.yy4AcquCnt),
            year5AcquiredCount: this.toInteger(item.yy5AcquCnt),
            year6AcquiredCount: this.toInteger(item.yy6AcquCnt),
            rawPayload: item,
          }),
        );
        syncedCount += 1;
      }

      pageNo += 1;
    } while ((pageNo - 1) * numOfRows < totalCount);

    return {
      source,
      baseYear,
      totalCount,
      syncedCount,
    };
  }

  async syncQnetPassRateStats(baseYear: number) {
    const source = "qnet-pass-rate-stat";
    const gradeCodes = ["10", "20", "30", "40", "41"];
    const numOfRows = 100;
    let syncedCount = 0;
    let totalCount = 0;

    for (const gradeCode of gradeCodes) {
      let pageNo = 1;
      let gradeTotalCount = 0;

      do {
        const page = await this.qnetPassRateStatClient.fetchPage(
          baseYear,
          gradeCode,
          pageNo,
          numOfRows,
        );
        gradeTotalCount = page.totalCount;

        for (const item of page.items) {
          const implementationYear = this.toInteger(item.implYy);
          const implementationSeq = String(item.implSeq);
          const externalId = [
            baseYear,
            gradeCode,
            implementationYear,
            implementationSeq,
            item.emqualDispNm,
          ].join(":");
          const receptionCount = this.toInteger(item.recptCnt);
          const writtenPassCount = this.toInteger(item.pilPassCnt);
          const practicalPassCount = this.toInteger(item.silPassCnt);

          await this.passRateStats.save(
            this.passRateStats.create({
              ...(await this.passRateStats.findOneBy({
                externalSource: source,
                externalId,
              })),
              externalSource: source,
              externalId,
              baseYear,
              gradeCode,
              gradeName: item.grdNm,
              implementationYear,
              implementationSeq,
              eligibilityName: item.emqualDispNm,
              receptionCount,
              writtenPassCount,
              practicalPassCount,
              writtenPassRate: this.rate(writtenPassCount, receptionCount),
              practicalPassRate: this.rate(practicalPassCount, receptionCount),
              rawPayload: item,
            }),
          );
          syncedCount += 1;
        }

        pageNo += 1;
      } while ((pageNo - 1) * numOfRows < gradeTotalCount);

      totalCount += gradeTotalCount;
    }

    return {
      source,
      baseYear,
      totalCount,
      syncedCount,
    };
  }

  async syncQnetRoundPassRateStats(baseYear: number) {
    const source = "qnet-round-pass-rate-stat";
    const gradeCodes = ["10", "20", "30", "40", "41"];
    const numOfRows = 100;
    let syncedCount = 0;
    let totalCount = 0;

    for (const gradeCode of gradeCodes) {
      let pageNo = 1;
      let gradeTotalCount = 0;

      do {
        const page = await this.qnetRoundPassRateStatClient.fetchPage(
          baseYear,
          gradeCode,
          pageNo,
          numOfRows,
        );
        gradeTotalCount = page.totalCount;

        for (const item of page.items) {
          const jmCd = String(item.jmCd);
          const implementationYear = this.toInteger(item.implYy);
          const implementationSeq = String(item.implSeq);
          const examType = item.examTypCcd;
          const externalId = [
            baseYear,
            gradeCode,
            jmCd,
            implementationYear,
            implementationSeq,
            examType,
          ].join(":");
          const certification = await this.certifications.findOneBy({
            externalSource: "qnet-national-qualification-list",
            externalId: jmCd,
          });

          await this.roundPassRateStats.save(
            this.roundPassRateStats.create({
              ...(await this.roundPassRateStats.findOne({
                where: {
                  externalSource: source,
                  externalId,
                },
                relations: { certification: true },
              })),
              externalSource: source,
              externalId,
              certification: certification ?? undefined,
              baseYear,
              jmCd,
              jmName: item.jmFldNm,
              gradeCode,
              gradeName: item.grdNm,
              implementationYear,
              implementationSeq,
              examType,
              examineeCount: this.toInteger(item.recptNoCnt),
              passCount: this.toInteger(item.examPassCnt),
              passRate: this.toPercentNumber(item.passRate),
              rawPayload: item,
            }),
          );
          syncedCount += 1;
        }

        pageNo += 1;
      } while ((pageNo - 1) * numOfRows < gradeTotalCount);

      totalCount += gradeTotalCount;
    }

    return {
      source,
      baseYear,
      totalCount,
      syncedCount,
    };
  }

  async syncCertificationTags() {
    await this.certificationTagMappings.delete({ source: TagSource.NAME_RULE });
    await this.tags.delete({ type: TagType.KEYWORD });

    const rows = await this.certifications.find({
      where: { externalSource: "qnet-national-qualification-list" },
      order: { name: "ASC" },
    });
    let tagCount = 0;
    let mappingCount = 0;

    for (const certification of rows) {
      const tagInputs = this.buildCertificationTagInputs(certification);

      for (const input of tagInputs) {
        const tag = await this.findOrCreateTag(input.type, input.name);
        tagCount += tag.created ? 1 : 0;

        const existing = await this.certificationTagMappings.findOne({
          where: {
            certification: { id: certification.id },
            tag: { id: tag.entity.id },
          },
          relations: { certification: true, tag: true },
        });

        await this.certificationTagMappings.save(
          this.certificationTagMappings.create({
            ...existing,
            certification,
            tag: tag.entity,
            source: input.source,
            confidence: input.confidence,
            metadata: {
              generatedFrom: input.generatedFrom,
            },
          }),
        );
        mappingCount += existing ? 0 : 1;
      }
    }

    return {
      source: "certification-tag-generator",
      certificationCount: rows.length,
      createdTagCount: tagCount,
      createdMappingCount: mappingCount,
    };
  }

  private buildCertificationTagInputs(certification: CertificationEntity) {
    const rawPayload = certification.rawPayload ?? {};
    const qnet = (key: string) => this.cleanTagName(rawPayload[key]);
    const tags: Array<{
      type: TagType;
      name: string;
      source: TagSource;
      confidence: number;
      generatedFrom: string;
    }> = [];

    this.pushTag(
      tags,
      TagType.QUALIFICATION_TYPE,
      qnet("qualgbnm"),
      TagSource.QNET,
      1,
      "qualgbnm",
    );
    this.pushTag(
      tags,
      TagType.SERIES,
      qnet("seriesnm"),
      TagSource.QNET,
      1,
      "seriesnm",
    );
    this.pushTag(
      tags,
      TagType.FIELD,
      qnet("obligfldnm"),
      TagSource.QNET,
      1,
      "obligfldnm",
    );
    this.pushTag(
      tags,
      TagType.SUBFIELD,
      qnet("mdobligfldnm"),
      TagSource.QNET,
      1,
      "mdobligfldnm",
    );

    const existingTagNames = new Set(tags.map((tag) => tag.name));

    for (const keyword of this.extractNameKeywords(certification.name)) {
      if (existingTagNames.has(keyword)) {
        continue;
      }

      this.pushTag(
        tags,
        TagType.KEYWORD,
        keyword,
        TagSource.NAME_RULE,
        0.75,
        "name",
      );
    }

    const unique = new Map<string, (typeof tags)[number]>();
    for (const tag of tags) {
      unique.set(`${tag.type}:${tag.name}`, tag);
    }

    return [...unique.values()];
  }

  private pushTag(
    tags: Array<{
      type: TagType;
      name: string;
      source: TagSource;
      confidence: number;
      generatedFrom: string;
    }>,
    type: TagType,
    name: string | undefined,
    source: TagSource,
    confidence: number,
    generatedFrom: string,
  ) {
    const cleanName = this.cleanTagName(name);

    if (!cleanName) {
      return;
    }

    tags.push({
      type,
      name: cleanName,
      source,
      confidence,
      generatedFrom,
    });
  }

  private async findOrCreateTag(type: TagType, name: string) {
    const slug = this.slugifyTag(name);
    const existing = await this.tags.findOneBy({ type, slug });

    if (existing) {
      return { entity: existing, created: false };
    }

    const created = await this.tags.save(
      this.tags.create({
        type,
        name,
        slug,
      }),
    );

    return { entity: created, created: true };
  }

  private extractNameKeywords(name: string) {
    const normalized = name
      .replace(/\([^)]*\)/g, " ")
      .replace(/[0-9]+급/g, " ")
      .replace(/기술사|기능장|기사|산업기사|기능사|전문자격/g, " ")
      .replace(/[^가-힣A-Za-z0-9]+/g, " ")
      .trim();
    const tokens = normalized
      .split(/\s+/)
      .map((token) => token.trim())
      .filter((token) => token.length >= 2);

    if (tokens.length > 0) {
      return tokens.slice(0, 3);
    }

    const compact = normalized.replace(/\s/g, "");
    return compact.length >= 2 ? [compact] : [];
  }

  private cleanTagName(value: unknown) {
    if (value == null) {
      return undefined;
    }

    const text = String(value).trim();
    return text.length > 0 ? text : undefined;
  }

  private slugifyTag(name: string) {
    return name
      .trim()
      .toLowerCase()
      .replace(/\s+/g, "-")
      .replace(/[./]+/g, "-")
      .replace(/[^가-힣a-z0-9-]+/g, "")
      .replace(/-+/g, "-")
      .replace(/^-|-$/g, "");
  }

  private rate(part: number, total: number) {
    if (total <= 0) {
      return 0;
    }

    return Number(((part / total) * 100).toFixed(4));
  }

  private toInteger(value: string | number | undefined) {
    if (value == null) {
      return 0;
    }

    const parsed = Number(String(value).replace(/,/g, ""));
    return Number.isFinite(parsed) ? parsed : 0;
  }

  private toPercentNumber(value: string | number | undefined) {
    if (value == null) {
      return 0;
    }

    const parsed = Number(String(value).replace("%", "").replace(/,/g, ""));
    return Number.isFinite(parsed) ? parsed : 0;
  }
}

type RankingRawRow = {
  id: string;
  name: string;
  category: string;
  organization?: string;
  primaryCount?: number | string;
  passCount?: number | string;
  passRate?: number | string;
  metaLabel?: string;
};
