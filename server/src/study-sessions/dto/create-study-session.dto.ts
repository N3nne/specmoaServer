import { IsDateString, IsInt, IsOptional, IsString, Min } from 'class-validator';

export class CreateStudySessionDto {
  @IsDateString()
  startedAt: string;

  @IsDateString()
  @IsOptional()
  endedAt?: string;

  @IsInt()
  @Min(0)
  durationSeconds: number;

  @IsString()
  @IsOptional()
  certificationId?: string;

  @IsString()
  @IsOptional()
  note?: string;
}
