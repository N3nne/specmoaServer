import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';

import { CertificationEntity } from '../certifications/entities/certification.entity';
import { UsersService } from '../users/users.service';
import { CreateStudyTaskDto } from './dto/create-study-task.dto';
import { StudyTaskEntity } from './entities/study-task.entity';

@Injectable()
export class StudyTasksService {
  constructor(
    @InjectRepository(StudyTaskEntity)
    private readonly tasks: Repository<StudyTaskEntity>,
    @InjectRepository(CertificationEntity)
    private readonly certifications: Repository<CertificationEntity>,
    private readonly users: UsersService,
  ) {}

  async today(userId?: string) {
    const user = await this.users.getRequestUser(userId);
    const today = new Date().toISOString().slice(0, 10);
    const tasks = await this.tasks.find({
      where: { user: { id: user.id }, dueDate: today },
      relations: { certification: true },
      order: { createdAt: 'ASC' },
    });

    return tasks.map((task) => ({
      id: task.id,
      title: task.title,
      minutes: task.minutes,
      dueDate: task.dueDate,
      completed: Boolean(task.completedAt),
      certification: task.certification
        ? {
            id: task.certification.id,
            name: task.certification.name,
          }
        : undefined,
    }));
  }

  async create(userId: string | undefined, dto: CreateStudyTaskDto) {
    const user = await this.users.getRequestUser(userId);
    const certification = dto.certificationId
      ? await this.certifications.findOneBy({ id: dto.certificationId })
      : null;

    if (dto.certificationId && !certification) {
      throw new NotFoundException(`Certification ${dto.certificationId} was not found.`);
    }

    const task = await this.tasks.save(
      this.tasks.create({
        user,
        certification: certification ?? undefined,
        title: dto.title,
        minutes: dto.minutes,
        dueDate: dto.dueDate,
      }),
    );

    return { id: task.id };
  }

  async complete(userId: string | undefined, taskId: string) {
    const user = await this.users.getRequestUser(userId);
    const task = await this.tasks.findOne({
      where: { id: taskId, user: { id: user.id } },
      relations: { user: true },
    });

    if (!task) {
      throw new NotFoundException(`Study task ${taskId} was not found.`);
    }

    task.completedAt = new Date();
    await this.tasks.save(task);

    return { id: task.id, completed: true, completedAt: task.completedAt };
  }
}
