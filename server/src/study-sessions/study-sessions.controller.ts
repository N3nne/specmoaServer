import { Body, Controller, Get, Headers, Post } from "@nestjs/common";

import { getUserIdFromHeaders } from "../common/request-user";
import { CreateStudySessionDto } from "./dto/create-study-session.dto";
import { StudySessionsService } from "./study-sessions.service";

@Controller("study-sessions")
export class StudySessionsController {
  constructor(private readonly studySessions: StudySessionsService) {}

  @Get("today")
  today(@Headers() headers: Record<string, unknown>) {
    return this.studySessions.today(getUserIdFromHeaders(headers));
  }

  @Get("summary")
  summary(@Headers() headers: Record<string, unknown>) {
    return this.studySessions.summary(getUserIdFromHeaders(headers));
  }

  @Post()
  create(
    @Headers() headers: Record<string, unknown>,
    @Body() dto: CreateStudySessionDto,
  ) {
    return this.studySessions.create(getUserIdFromHeaders(headers), dto);
  }
}
