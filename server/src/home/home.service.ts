import { Injectable } from "@nestjs/common";
import { InjectRepository } from "@nestjs/typeorm";
import { Brackets, Repository } from "typeorm";

import {
  CommunityQnaPostEntity,
  CommunityQnaStatus,
} from "../community/entities/community-qna-post.entity";
import {
  SuccessStoryEntity,
  SuccessStoryStatus,
} from "../community/entities/success-story.entity";
import { CertificationRoundPassRateStatEntity } from "../certifications/entities/certification-round-pass-rate-stat.entity";
import { ExamScheduleEntity } from "../certifications/entities/exam-schedule.entity";
import {
  UserCertificationEntity,
  UserCertificationStatus,
} from "../certifications/entities/user-certification.entity";
import { UsersService } from "../users/users.service";

@Injectable()
export class HomeService {
  constructor(
    @InjectRepository(UserCertificationEntity)
    private readonly userCertifications: Repository<UserCertificationEntity>,
    @InjectRepository(ExamScheduleEntity)
    private readonly examSchedules: Repository<ExamScheduleEntity>,
    @InjectRepository(CertificationRoundPassRateStatEntity)
    private readonly roundPassRateStats: Repository<CertificationRoundPassRateStatEntity>,
    @InjectRepository(CommunityQnaPostEntity)
    private readonly qnaPosts: Repository<CommunityQnaPostEntity>,
    @InjectRepository(SuccessStoryEntity)
    private readonly successStories: Repository<SuccessStoryEntity>,
    private readonly users: UsersService,
  ) {}

  async getHome(userId?: string) {
    const user = await this.users.getRequestUser(userId);
    const [
      myCertifications,
      popularCertifications,
      popularQuestions,
      successStories,
    ] = await Promise.all([
      this.getMyCertifications(user.id),
      this.getPopularCertifications(),
      this.getPopularQuestions(),
      this.getSuccessStories(),
    ]);

    return {
      myCertifications,
      popularCertifications,
      popularQuestions,
      successStories,
    };
  }

  private async getMyCertifications(userId: string) {
    const rows = await this.userCertifications.find({
      where: { user: { id: userId } },
      relations: { certification: true },
      order: { updatedAt: "DESC" },
    });
    const today = this.today();
    const pendingRows = rows.filter(
      (row) => row.status !== UserCertificationStatus.CERTIFIED,
    );
    const directSchedules = await this.findNextDirectSchedules(
      pendingRows.map((row) => row.certification.id),
      today,
    );
    const sharedKeywords = pendingRows
      .filter((row) => !directSchedules.has(row.certification.id))
      .map((row) =>
        this.scheduleKeywordForCertification(row.certification.name),
      )
      .filter(Boolean) as string[];
    const sharedSchedules = await this.findNextSharedSchedules(
      sharedKeywords,
      today,
    );

    return rows.map((row) => {
      const sharedKeyword = this.scheduleKeywordForCertification(
        row.certification.name,
      );
      const nextSchedule =
        row.status === UserCertificationStatus.CERTIFIED
          ? undefined
          : (directSchedules.get(row.certification.id) ??
            (sharedKeyword ? sharedSchedules.get(sharedKeyword) : undefined));

      return {
        id: row.id,
        status: row.status,
        certified: row.status === UserCertificationStatus.CERTIFIED,
        certifiedOn: row.certifiedOn,
        targetExamDate: row.targetExamDate,
        certification: {
          id: row.certification.id,
          name: row.certification.name,
          category: row.certification.category,
        },
        nextExam: nextSchedule
          ? {
              id: nextSchedule.id,
              title: nextSchedule.title,
              startsOn: nextSchedule.startsOn,
              dDay: this.daysUntil(nextSchedule.startsOn),
            }
          : undefined,
      };
    });
  }

  private async findNextDirectSchedules(
    certificationIds: string[],
    today: string,
  ) {
    const uniqueIds = [...new Set(certificationIds)].filter(Boolean);
    if (uniqueIds.length === 0) {
      return new Map<string, ExamScheduleEntity>();
    }

    const schedules = await this.examSchedules
      .createQueryBuilder("schedule")
      .leftJoinAndSelect("schedule.certification", "certification")
      .where("certification.id IN (:...certificationIds)", {
        certificationIds: uniqueIds,
      })
      .andWhere("schedule.startsOn >= :today", { today })
      .orderBy("schedule.startsOn", "ASC")
      .addOrderBy("schedule.type", "ASC")
      .getMany();

    const byCertification = new Map<string, ExamScheduleEntity>();
    for (const schedule of schedules) {
      const certificationId = schedule.certification?.id;
      if (certificationId && !byCertification.has(certificationId)) {
        byCertification.set(certificationId, schedule);
      }
    }

    return byCertification;
  }

  private async findNextSharedSchedules(keywords: string[], today: string) {
    const uniqueKeywords = [...new Set(keywords)].filter(Boolean);
    if (uniqueKeywords.length === 0) {
      return new Map<string, ExamScheduleEntity>();
    }

    const schedules = await this.examSchedules
      .createQueryBuilder("schedule")
      .where("schedule.startsOn >= :today", { today })
      .andWhere(
        new Brackets((query) => {
          uniqueKeywords.forEach((keyword, index) => {
            const clause = `schedule.title ILIKE :keyword${index}`;
            const parameters = { [`keyword${index}`]: `%${keyword}%` };
            if (index === 0) {
              query.where(clause, parameters);
            } else {
              query.orWhere(clause, parameters);
            }
          });
        }),
      )
      .orderBy("schedule.startsOn", "ASC")
      .addOrderBy("schedule.type", "ASC")
      .getMany();

    const byKeyword = new Map<string, ExamScheduleEntity>();
    for (const schedule of schedules) {
      for (const keyword of uniqueKeywords) {
        if (!byKeyword.has(keyword) && schedule.title.includes(keyword)) {
          byKeyword.set(keyword, schedule);
        }
      }
    }

    return byKeyword;
  }

  private scheduleKeywordForCertification(name: string) {
    if (name.includes("기능장")) {
      return "정기 기능장";
    }
    if (name.includes("산업기사") || name.includes("기사")) {
      return "정기 기사";
    }
    if (name.includes("기능사")) {
      return "정기 기능사";
    }
    if (name.includes("기술사")) {
      return "정기 기술사";
    }
    return undefined;
  }

  private async getPopularCertifications() {
    const rows = await this.roundPassRateStats
      .createQueryBuilder("stat")
      .innerJoin("stat.certification", "certification")
      .select("certification.id", "id")
      .addSelect("certification.name", "name")
      .addSelect("certification.category", "category")
      .addSelect("sum(stat.examineeCount)::int", "examineeCount")
      .groupBy("certification.id")
      .addGroupBy("certification.name")
      .addGroupBy("certification.category")
      .orderBy("sum(stat.examineeCount)", "DESC")
      .limit(5)
      .getRawMany<{
        id: string;
        name: string;
        category: string;
        examineeCount: number;
      }>();

    return rows.map((row, index) => ({
      rank: index + 1,
      id: row.id,
      name: row.name,
      category: row.category,
      examineeCount: Number(row.examineeCount ?? 0),
    }));
  }

  private async getPopularQuestions() {
    const rows = await this.qnaPosts.find({
      where: [
        { status: CommunityQnaStatus.OPEN },
        { status: CommunityQnaStatus.ANSWERED },
      ],
      relations: {
        author: true,
        certification: true,
        answers: { author: true },
      },
      order: { viewCount: "DESC", likeCount: "DESC", createdAt: "DESC" },
      take: 5,
    });

    if (rows.length === 0) {
      return Array.from({ length: 5 }, (_, index) => ({
        id: `dummy-question-${index + 1}`,
        title: `질문 ${index + 1}`,
        body: "",
        certificationName: "자격증",
        authorName: "스펙모아",
        likeCount: 0,
        commentCount: 0,
        viewCount: 0,
        acceptedAnswer: undefined,
        dummy: true,
      }));
    }

    return rows.map((row) => {
      const acceptedAnswer = row.answers?.find(
        (answer) => answer.id === row.acceptedAnswerId,
      );
      return {
        id: row.id,
        title: row.title,
        body: row.body,
        certificationName: row.certification?.name ?? "자격증",
        authorName: row.author?.displayName ?? "익명",
        likeCount: row.likeCount,
        commentCount: row.answerCount,
        viewCount: row.viewCount,
        acceptedAnswer: acceptedAnswer
          ? {
              id: acceptedAnswer.id,
              body: acceptedAnswer.body,
              likeCount: acceptedAnswer.likeCount,
              author: acceptedAnswer.author
                ? {
                    id: acceptedAnswer.author.id,
                    displayName: acceptedAnswer.author.displayName,
                  }
                : undefined,
              accepted: true,
              dummy: false,
            }
          : undefined,
        dummy: false,
      };
    });
  }

  private async getSuccessStories() {
    const rows = await this.successStories.find({
      where: { status: SuccessStoryStatus.PUBLISHED },
      relations: { author: true, certification: true },
      order: { viewCount: "DESC", likeCount: "DESC", createdAt: "DESC" },
      take: 5,
    });

    if (rows.length === 0) {
      return Array.from({ length: 5 }, (_, index) => ({
        id: `dummy-story-${index + 1}`,
        title: `후기 ${index + 1}`,
        description: "합격 후기가 등록되면 이곳에 표시됩니다.",
        certificationName: "자격증",
        studyPeriodDays: 21,
        studyMethod: "이론 1회독 + 기출 반복",
        score: "82점",
        examAttempt: "초시",
        authorName: "스펙모아",
        likeCount: 0,
        commentCount: 0,
        viewCount: 0,
        dummy: true,
      }));
    }

    return rows.map((row) => {
      const metadata = row.metadata ?? {};
      return {
        id: row.id,
        title: row.title,
        description:
          typeof metadata.subtitle === "string" && metadata.subtitle.length > 0
            ? metadata.subtitle
            : row.body,
        body: row.body,
        certificationName: row.certification?.name ?? "자격증",
        studyPeriodDays: row.studyPeriodDays,
        studyMethod:
          typeof metadata.studyMethod === "string" ? metadata.studyMethod : "",
        score: typeof metadata.score === "string" ? metadata.score : "",
        examAttempt: row.examAttempt,
        authorName: row.author?.displayName ?? "익명",
        likeCount: row.likeCount,
        commentCount: 0,
        viewCount: row.viewCount,
        dummy: false,
      };
    });
  }

  private today() {
    return new Date().toISOString().slice(0, 10);
  }

  private daysUntil(date: string) {
    const today = new Date(`${this.today()}T00:00:00.000Z`);
    const target = new Date(`${date}T00:00:00.000Z`);
    return Math.ceil((target.getTime() - today.getTime()) / 86_400_000);
  }
}
