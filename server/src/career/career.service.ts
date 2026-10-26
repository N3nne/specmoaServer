import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { JOB_OCCUPATIONS } from '../jobs/job-occupations';
import { UserSpecEntity } from '../specs/entities/user-spec.entity';
import { SpecType } from '../specs/spec-types';
import { UserProfileEntity } from '../users/entities/user-profile.entity';
import { CAREER_PREFERENCES_KEY, CAREER_PREFERENCES_VERSION, readCareerPreferences } from './career-preferences';
import { UpdateCareerPreferencesDto } from './dto/update-career-preferences.dto';
import { prepareSpecAnalysis } from './spec-analysis-context';

@Injectable()
export class CareerService {
  constructor(
    @InjectRepository(UserProfileEntity) private readonly profiles: Repository<UserProfileEntity>,
    @InjectRepository(UserSpecEntity) private readonly specs: Repository<UserSpecEntity>,
  ) {}

  occupations() {
    return { version: 'job-occupations-v1', items: JOB_OCCUPATIONS };
  }

  async preferences(userId: string) {
    const profile = await this.profiles.findOne({ where: { user: { id: userId } }, select: { id: true, preferences: true } });
    return readCareerPreferences(profile ? profile.preferences : {});
  }

  async updatePreferences(userId: string, dto: UpdateCareerPreferencesDto) {
    const career = { version: CAREER_PREFERENCES_VERSION, desiredOccupations: [...dto.desiredOccupations], updatedAt: new Date().toISOString() };
    // One atomic upsert preserves unrelated preferences and handles simultaneous first saves.
    const result = await this.profiles.createQueryBuilder().insert().into(UserProfileEntity)
      .values({ user: { id: userId }, preferences: { [CAREER_PREFERENCES_KEY]: career } })
      .onConflict(`("userId") DO UPDATE SET "preferences" =
        (CASE WHEN jsonb_typeof("user_profiles"."preferences") = 'object'
          THEN "user_profiles"."preferences" ELSE '{}'::jsonb END) || EXCLUDED."preferences",
        "updatedAt" = CURRENT_TIMESTAMP`)
      .returning(['preferences']).execute();
    return readCareerPreferences(result.raw[0].preferences);
  }

  async analysisContext(userId: string) {
    const preferences = await this.preferences(userId);
    const rows = await this.specs.find({ where: { userId }, order: { createdAt: 'ASC', id: 'ASC' } });
    const specs = rows.map(prepareSpecAnalysis);
    return {
      version: 'career-context-v1', generatedAt: new Date().toISOString(), preferences,
      summary: {
        totalSpecs: specs.length,
        unsupportedSpecs: specs.filter(spec => spec.status === 'unsupported').length,
        byType: Object.values(SpecType).map(type => {
          const group = specs.filter(spec => spec.type === type);
          return { type, total: group.length, available: group.filter(spec => spec.status === 'available').length,
            partial: group.filter(spec => spec.status === 'partial').length, empty: group.filter(spec => spec.status === 'empty').length };
        }),
      },
      specs,
      privacy: {
        mode: 'server_only', externalAiTransmissionAllowed: false, userProvidedTextMayContainPersonalData: true,
        excludedFields: ['certificateNumber', 'registrationNumber', 'certificationId', 'reminders', 'reminder', 'relatedUrl', 'repositoryUrl', 'demoUrl', 'projectUrl'],
      },
    };
  }
}
