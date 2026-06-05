import { CertificationEntity } from '../entities/certification.entity';

export class CertificationDto {
  id: string;
  name: string;
  englishName?: string;
  category: string;
  organization?: string;
  description?: string;
  officialUrl?: string;

  static fromEntity(entity: CertificationEntity): CertificationDto {
    return {
      id: entity.id,
      name: entity.name,
      englishName: entity.englishName,
      category: entity.category,
      organization: entity.organization,
      description: entity.description,
      officialUrl: entity.officialUrl,
    };
  }
}
