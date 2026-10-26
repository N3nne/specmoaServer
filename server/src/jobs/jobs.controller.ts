import { Controller, Get, Headers, Param, ParseUUIDPipe, Query } from '@nestjs/common';
import { getUserIdFromHeaders } from '../common/request-user';
import { ListJobsDto } from './dto/list-jobs.dto';
import { JobsService } from './jobs.service';

@Controller('jobs')
export class JobsController {
  constructor(private readonly jobs: JobsService) {}

  @Get()
  list(@Query() query: ListJobsDto) { return this.jobs.list(query); }

  @Get('facets')
  facets(@Query() query: ListJobsDto) { return this.jobs.facets(query); }

  @Get(':id/match')
  match(@Headers() headers: Record<string, unknown>, @Param('id', ParseUUIDPipe) id: string) {
    return this.jobs.match(getUserIdFromHeaders(headers), id);
  }

  @Get('demo/:externalId')
  demoDetail(@Param('externalId') externalId: string) { return this.jobs.demoDetail(externalId); }

  @Get(':id')
  detail(@Param('id', ParseUUIDPipe) id: string) { return this.jobs.detail(id); }
}
