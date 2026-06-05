import { Body, Controller, Get, Headers, Param, Patch, Post } from '@nestjs/common';

import { getUserIdFromHeaders } from '../common/request-user';
import { CreateStudyTaskDto } from './dto/create-study-task.dto';
import { StudyTasksService } from './study-tasks.service';

@Controller('study-tasks')
export class StudyTasksController {
  constructor(private readonly studyTasks: StudyTasksService) {}

  @Get('today')
  today(@Headers() headers: Record<string, unknown>) {
    return this.studyTasks.today(getUserIdFromHeaders(headers));
  }

  @Post()
  create(
    @Headers() headers: Record<string, unknown>,
    @Body() dto: CreateStudyTaskDto,
  ) {
    return this.studyTasks.create(getUserIdFromHeaders(headers), dto);
  }

  @Patch(':id/complete')
  complete(@Headers() headers: Record<string, unknown>, @Param('id') id: string) {
    return this.studyTasks.complete(getUserIdFromHeaders(headers), id);
  }
}
