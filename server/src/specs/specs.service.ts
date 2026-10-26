import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { CertificationEntity } from '../certifications/entities/certification.entity';
import { CreateSpecDto, ListSpecsDto, UpdateSpecDto } from './dto/spec.dto';
import { UserSpecEntity } from './entities/user-spec.entity';
import { normalizeSpecData, specTitle } from './spec-field-policy';
import { SpecType, specGroup } from './spec-types';

@Injectable()
export class SpecsService {
  constructor(
    @InjectRepository(UserSpecEntity) private readonly specs: Repository<UserSpecEntity>,
    @InjectRepository(CertificationEntity) private readonly certifications: Repository<CertificationEntity>,
  ) {}

  async list(userId: string, query: ListSpecsDto) {
    const [items, total] = await this.specs.findAndCount({
      where: { userId, ...(query.type ? { type: query.type } : {}) },
      order: { createdAt: 'DESC', id: 'DESC' }, take: query.limit, skip: query.offset,
    });
    return { items: items.map(item => this.serialize(item)), total, limit: query.limit, offset: query.offset };
  }

  async summary(userId: string) {
    const rows = await this.specs.createQueryBuilder('spec')
      .select('spec.type', 'type').addSelect('COUNT(*)', 'count')
      .where('spec.userId = :userId', { userId }).groupBy('spec.type')
      .getRawMany<{ type: SpecType; count: string }>();
    const byType = Object.fromEntries(Object.values(SpecType).map(type => [type, 0]));
    for (const row of rows) byType[row.type] = Number(row.count);
    const examScore = Object.values(SpecType).filter(type => specGroup(type) === 'exam_score').reduce((sum, type) => sum + byType[type], 0);
    const total = Object.values(byType).reduce((sum, count) => sum + count, 0);
    return { total, examScore, activityExperience: total - examScore, byType };
  }

  async find(userId: string, id: string) {
    return this.serialize(await this.owned(userId, id));
  }

  async create(userId: string, dto: CreateSpecDto) {
    const data = await this.prepare(dto.type, dto.data ?? {});
    const item = this.specs.create({ userId, type: dto.type, data, title: specTitle(dto.type, data),
      certificationId: typeof data.certificationId === 'string' ? data.certificationId : null });
    return this.serialize(await this.specs.save(item));
  }

  async update(userId: string, id: string, dto: UpdateSpecDto) {
    const item = await this.owned(userId, id);
    item.data = await this.prepare(item.type, { ...item.data,
      ...(item.type === SpecType.CERTIFICATION ? { certificationId: item.certificationId } : {}), ...dto.data });
    item.title = specTitle(item.type, item.data);
    item.certificationId = typeof item.data.certificationId === 'string' ? item.data.certificationId : null;
    return this.serialize(await this.specs.save(item));
  }

  async remove(userId: string, id: string) {
    const item = await this.owned(userId, id);
    await this.specs.delete({ id: item.id, userId });
    return { deleted: true, id: item.id };
  }

  private async owned(userId: string, id: string) {
    const item = await this.specs.findOneBy({ id, userId });
    if (!item) throw new NotFoundException('스펙을 찾을 수 없습니다.');
    return item;
  }

  private async prepare(type: SpecType, raw: Record<string, unknown>) {
    const data = normalizeSpecData(type, raw);
    if (typeof data.certificationId === 'string') {
      const certification = await this.certifications.findOneBy({ id: data.certificationId });
      if (!certification) throw new NotFoundException('공식 자격증을 찾을 수 없습니다.');
      // Catalog selection can fill missing source information, but never authenticates ownership.
      if (!Object.prototype.hasOwnProperty.call(raw, 'name')) data.name = certification.name;
      if (!Object.prototype.hasOwnProperty.call(raw, 'issuer') && certification.organization) data.issuer = certification.organization;
    }
    return data;
  }

  private serialize(item: UserSpecEntity) {
    const data = { ...item.data };
    if (item.type === SpecType.CERTIFICATION) {
      delete data.certificationId;
      if (item.certificationId) data.certificationId = item.certificationId;
    }
    return { id: item.id, type: item.type, group: specGroup(item.type), title: item.title,
      data, verification: 'unverified', createdAt: item.createdAt, updatedAt: item.updatedAt };
  }
}
