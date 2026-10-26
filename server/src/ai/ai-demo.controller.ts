import {
  BadRequestException,
  Body,
  Controller,
  Get,
  Header,
  Headers,
  HttpCode,
  Post,
  Query,
} from '@nestjs/common';
import { IsEnum } from 'class-validator';
import { getUserIdFromHeaders } from '../common/request-user';
import { AiDemoService } from './ai-demo.service';
import { DemoProfile } from './demo-recommendation-data';

export class DemoRecommendationDto {
  @IsEnum(DemoProfile)
  profile: DemoProfile;
}

@Controller('ai/demo')
export class AiDemoController {
  constructor(private readonly ai: AiDemoService) {}

  @Get('status')
  @Header('Cache-Control', 'no-store')
  status() {
    return this.ai.availability();
  }

  @Post('recommendations')
  @HttpCode(200)
  @Header('Cache-Control', 'no-store')
  recommend(
    @Headers() headers: Record<string, unknown>,
    @Body() body: DemoRecommendationDto,
    @Query() query: Record<string, unknown>,
  ) {
    if (Object.keys(query).length)
      throw new BadRequestException('AI 시연은 가상 프로필 선택만 허용합니다.');
    return this.ai.recommend(body.profile, getUserIdFromHeaders(headers));
  }
}
