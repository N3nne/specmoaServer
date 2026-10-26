import { Type } from 'class-transformer';
import { IsEnum, IsInt, IsObject, IsOptional, Max, Min } from 'class-validator';
import { SpecType } from '../spec-types';

export class CreateSpecDto {
  @IsEnum(SpecType)
  type: SpecType;

  @IsOptional()
  @IsObject()
  data?: Record<string, unknown>;
}

export class UpdateSpecDto {
  @IsOptional()
  @IsObject()
  data?: Record<string, unknown>;
}

export class ListSpecsDto {
  @IsOptional()
  @IsEnum(SpecType)
  type?: SpecType;

  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  @Max(100)
  limit = 50;

  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(0)
  offset = 0;
}
