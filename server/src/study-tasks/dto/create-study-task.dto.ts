import { IsDateString, IsInt, IsOptional, IsString, Min } from 'class-validator';

export class CreateStudyTaskDto {
  @IsString()
  title: string;

  @IsInt()
  @Min(1)
  minutes: number;

  @IsDateString()
  dueDate: string;

  @IsString()
  @IsOptional()
  certificationId?: string;
}
