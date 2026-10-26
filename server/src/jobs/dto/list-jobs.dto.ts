import { Transform, Type } from 'class-transformer';
import { IsEnum, IsInt, IsOptional, IsString, Max, MaxLength, Min } from 'class-validator';
import { EducationLevel, EmploymentType, ExperienceLevel, JobSort, JobStatus } from '../job.types';

const trim = ({ value }: { value: unknown }) => typeof value === 'string' ? value.trim() : value;

export class ListJobsDto {
  @IsOptional() @Transform(trim) @IsString() @MaxLength(100) q?: string;
  @IsOptional() @Transform(trim) @IsString() @MaxLength(60) occupation?: string;
  @IsOptional() @Transform(trim) @IsString() @MaxLength(60) region?: string;
  @IsOptional() @IsEnum(EmploymentType) employmentType?: EmploymentType;
  @IsOptional() @IsEnum(EducationLevel) educationLevel?: EducationLevel;
  @IsOptional() @IsEnum(ExperienceLevel) experienceLevel?: ExperienceLevel;
  @IsEnum(JobStatus) status: JobStatus = JobStatus.OPEN;
  @IsEnum(JobSort) sort: JobSort = JobSort.LATEST;
  @Type(() => Number) @IsInt() @Min(1) @Max(100) limit = 20;
  @Type(() => Number) @IsInt() @Min(0) @Max(100000) offset = 0;
}
