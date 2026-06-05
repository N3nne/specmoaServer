import { Body, Controller, Get, Headers, Param, Post, Query } from '@nestjs/common';

import { getUserIdFromHeaders } from '../common/request-user';
import { CommunityService } from './community.service';

@Controller('community')
export class CommunityController {
  constructor(private readonly community: CommunityService) {}

  @Get('qna')
  findQnaPosts(
    @Query('tagId') tagId?: string,
    @Query('tag') tag?: string,
    @Query('q') q?: string,
    @Query('certificationId') certificationId?: string,
    @Query('sort') sort?: string,
    @Query('limit') limit?: string,
    @Query('offset') offset?: string,
  ) {
    return this.community.findQnaPosts({
      tagId,
      tag,
      q,
      certificationId,
      sort,
      limit: limit ? Number(limit) : undefined,
      offset: offset ? Number(offset) : undefined,
    });
  }

  @Get('qna/tags')
  findQnaTags() {
    return this.community.findAvailableTags();
  }

  @Post('qna')
  createQnaPost(
    @Headers() headers: Record<string, unknown>,
    @Body()
    body: {
      certificationId?: string;
      title?: string;
      body?: string;
      tags?: string[];
      isAnonymous?: boolean;
    },
  ) {
    return this.community.createQnaPost(getUserIdFromHeaders(headers), body);
  }

  @Post('qna/:id/view')
  recordQnaView(@Param('id') id: string) {
    return this.community.recordQnaView(id);
  }

  @Get('qna/:id/answers')
  findQnaAnswers(@Param('id') id: string) {
    return this.community.findQnaAnswers(id);
  }

  @Post('qna/:id/answers')
  createQnaAnswer(
    @Param('id') id: string,
    @Headers() headers: Record<string, unknown>,
    @Body() body: { body?: string },
  ) {
    return this.community.createQnaAnswer(
      id,
      getUserIdFromHeaders(headers),
      body,
    );
  }

  @Post('qna/:id/answers/:answerId/accept')
  acceptQnaAnswer(
    @Param('id') id: string,
    @Param('answerId') answerId: string,
    @Headers() headers: Record<string, unknown>,
  ) {
    return this.community.acceptQnaAnswer(
      id,
      answerId,
      getUserIdFromHeaders(headers),
    );
  }

  @Get('success-stories')
  findSuccessStories(
    @Query('q') q?: string,
    @Query('certificationId') certificationId?: string,
    @Query('sort') sort?: string,
    @Query('limit') limit?: string,
    @Query('offset') offset?: string,
  ) {
    return this.community.findSuccessStories({
      q,
      certificationId,
      sort,
      limit: limit ? Number(limit) : undefined,
      offset: offset ? Number(offset) : undefined,
    });
  }

  @Post('success-stories')
  createSuccessStory(
    @Headers() headers: Record<string, unknown>,
    @Body()
    body: {
      certificationId?: string;
      title?: string;
      subtitle?: string;
      body?: string;
      studyPeriodDays?: number;
      studyMethod?: string;
      score?: string;
      examAttempt?: string;
    },
  ) {
    return this.community.createSuccessStory(getUserIdFromHeaders(headers), body);
  }

  @Post('success-stories/:id/view')
  recordSuccessStoryView(@Param('id') id: string) {
    return this.community.recordSuccessStoryView(id);
  }
}
