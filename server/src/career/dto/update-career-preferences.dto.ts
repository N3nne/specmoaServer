import { ArrayMaxSize, ArrayUnique, IsArray, IsIn } from 'class-validator';
import { JOB_OCCUPATION_CODES, JobOccupation } from '../../jobs/job-occupations';

export class UpdateCareerPreferencesDto {
  @IsArray()
  @ArrayMaxSize(JOB_OCCUPATION_CODES.length)
  @ArrayUnique()
  @IsIn(JOB_OCCUPATION_CODES, { each: true })
  desiredOccupations: JobOccupation[];
}

export class CareerQueryDto {}
