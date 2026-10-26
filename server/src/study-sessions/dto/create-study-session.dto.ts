import { IsDateString, IsInt, IsOptional, IsString, IsUUID, Max, Min } from 'class-validator';

export class CreateStudySessionDto {
  @IsDateString()
  startedAt: string;

  @IsDateString()
  @IsOptional()
  endedAt?: string;

  @IsInt()
  @Min(0)
  @Max(3600)
  durationSeconds: number;

  @IsString()
  @IsOptional()
  certificationId?: string;

  @IsOptional()
  @IsUUID()
  specId?: string;

  @IsString()
  @IsOptional()
  note?: string;
}
