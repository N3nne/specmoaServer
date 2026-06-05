import { IsDateString, IsEnum, IsInt, IsOptional, IsString, Max, Min } from 'class-validator';

import { UserCertificationStatus } from '../entities/user-certification.entity';

export class RegisterUserCertificationDto {
  @IsString()
  certificationId: string;

  @IsEnum(UserCertificationStatus)
  @IsOptional()
  status?: UserCertificationStatus;

  @IsInt()
  @Min(0)
  @Max(100)
  @IsOptional()
  progress?: number;

  @IsDateString()
  @IsOptional()
  targetExamDate?: string;

  @IsDateString()
  @IsOptional()
  certifiedOn?: string;

  @IsString()
  @IsOptional()
  certificateNumber?: string;

  @IsString()
  @IsOptional()
  preparationCategory?: string;

  @IsString()
  @IsOptional()
  notes?: string;
}
