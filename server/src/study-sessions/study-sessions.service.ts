import { Injectable, NotFoundException } from "@nestjs/common";
import { InjectRepository } from "@nestjs/typeorm";
import { Between, In, Repository } from "typeorm";

import { CertificationEntity } from "../certifications/entities/certification.entity";
import { UsersService } from "../users/users.service";
import { CreateStudySessionDto } from "./dto/create-study-session.dto";
import { StudySessionEntity } from "./entities/study-session.entity";

@Injectable()
export class StudySessionsService {
  constructor(
    @InjectRepository(StudySessionEntity)
    private readonly sessions: Repository<StudySessionEntity>,
    @InjectRepository(CertificationEntity)
    private readonly certifications: Repository<CertificationEntity>,
    private readonly users: UsersService,
  ) {}

  async today(userId?: string) {
    const user = await this.users.getRequestUser(userId);
    const { start, end } = this.todayRange();

    const sessions = await this.sessions.find({
      where: {
        user: { id: user.id },
        startedAt: Between(start, end),
      },
      relations: { certification: true },
      order: { startedAt: "DESC" },
    });

    return sessions.map((session) => this.serializeSession(session));
  }

  async summary(userId?: string) {
    const user = await this.users.getRequestUser(userId);
    const { start, end } = this.todayRange();

    const [todayRow, totalRow, recent] = await Promise.all([
      this.sessions
        .createQueryBuilder("session")
        .leftJoin("session.user", "sessionUser")
        .select("COALESCE(SUM(session.durationSeconds), 0)", "seconds")
        .where("sessionUser.id = :userId", { userId: user.id })
        .andWhere("session.startedAt BETWEEN :start AND :end", { start, end })
        .getRawOne<{ seconds: string }>(),
      this.sessions
        .createQueryBuilder("session")
        .leftJoin("session.user", "sessionUser")
        .select("COALESCE(SUM(session.durationSeconds), 0)", "seconds")
        .where("sessionUser.id = :userId", { userId: user.id })
        .getRawOne<{ seconds: string }>(),
      this.sessions.find({
        where: { user: { id: user.id } },
        relations: { certification: true },
        order: { startedAt: "DESC" },
        take: 5,
      }),
    ]);

    return {
      todaySeconds: Number(todayRow?.seconds ?? 0),
      totalSeconds: Number(totalRow?.seconds ?? 0),
      recent: recent.map((session) => this.serializeSession(session)),
    };
  }

  private serializeSession(session: StudySessionEntity) {
    return {
      id: session.id,
      startedAt: session.startedAt,
      endedAt: session.endedAt,
      durationSeconds: session.durationSeconds,
      note: session.note,
      certification: session.certification
        ? {
            id: session.certification.id,
            name: session.certification.name,
          }
        : undefined,
    };
  }

  private todayRange() {
    const now = new Date();
    const start = new Date(now);
    start.setHours(0, 0, 0, 0);
    const end = new Date(now);
    end.setHours(23, 59, 59, 999);
    return { start, end };
  }

  async create(userId: string | undefined, dto: CreateStudySessionDto) {
    const user = await this.users.getRequestUser(userId);
    const certification = dto.certificationId
      ? await this.certifications.findOneBy({ id: dto.certificationId })
      : null;

    if (dto.certificationId && !certification) {
      throw new NotFoundException(
        `Certification ${dto.certificationId} was not found.`,
      );
    }

    const session = await this.sessions.save(
      this.sessions.create({
        user,
        certification: certification ?? undefined,
        startedAt: new Date(dto.startedAt),
        endedAt: dto.endedAt ? new Date(dto.endedAt) : undefined,
        durationSeconds: dto.durationSeconds,
        note: dto.note,
      }),
    );
    await this.pruneRecentSessions(user.id);

    return { id: session.id };
  }

  private async pruneRecentSessions(userId: string) {
    const overflow = await this.sessions
      .createQueryBuilder("session")
      .leftJoin("session.user", "sessionUser")
      .select("session.id", "id")
      .where("sessionUser.id = :userId", { userId })
      .orderBy("session.startedAt", "DESC")
      .addOrderBy("session.createdAt", "DESC")
      .offset(5)
      .getRawMany<{ id: string }>();

    if (overflow.length === 0) {
      return;
    }

    await this.sessions.delete({
      id: In(overflow.map((session) => session.id)),
    });
  }
}
