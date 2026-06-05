import { Body, Controller, Delete, Get, Headers, Param, Post, Query } from '@nestjs/common';

import { getUserIdFromHeaders } from '../common/request-user';
import { CertificationsService } from './certifications.service';
import { RegisterUserCertificationDto } from './dto/register-user-certification.dto';

@Controller('certifications')
export class CertificationsController {
  constructor(private readonly certifications: CertificationsService) {}

  @Get()
  findAll() {
    return this.certifications.findAll();
  }

  @Get('search')
  search(
    @Query('q') q?: string,
    @Query('tagId') tagId?: string,
    @Query('sort') sort?: string,
    @Query('qualificationType') qualificationType?: string,
    @Query('limit') limit?: string,
  ) {
    return this.certifications.search({
      q,
      tagId,
      sort,
      qualificationType,
      limit: limit ? Number(limit) : undefined,
    });
  }

  @Get('tags')
  findSearchTags(
    @Query('limit') limit?: string,
    @Query('qualificationType') qualificationType?: string,
    @Query('q') q?: string,
  ) {
    return this.certifications.findSearchTags(
      limit ? Number(limit) : undefined,
      qualificationType,
      q,
    );
  }

  @Get('rankings')
  getRankings(
    @Query('metric') metric?: string,
    @Query('qualificationType') qualificationType?: string,
    @Query('tagId') tagId?: string,
    @Query('limit') limit?: string,
  ) {
    return this.certifications.getRankings({
      metric,
      qualificationType,
      tagId,
      limit: limit ? Number(limit) : undefined,
    });
  }

  @Get('user')
  findForUser(@Headers() headers: Record<string, unknown>) {
    return this.certifications.findForUser(getUserIdFromHeaders(headers));
  }

  @Get(':id/detail-page')
  findDetailPage(@Param('id') id: string) {
    return this.certifications.findDetailPage(id);
  }

  @Get(':id')
  findOne(@Param('id') id: string) {
    return this.certifications.findOne(id);
  }

  @Post('user')
  registerForUser(
    @Headers() headers: Record<string, unknown>,
    @Body() dto: RegisterUserCertificationDto,
  ) {
    return this.certifications.registerForUser(getUserIdFromHeaders(headers), dto);
  }

  @Delete('user/:id')
  removeForUser(
    @Param('id') id: string,
    @Headers() headers: Record<string, unknown>,
  ) {
    return this.certifications.removeForUser(
      getUserIdFromHeaders(headers),
      id,
    );
  }

  @Post('user/:id/delete')
  removeForUserByPost(
    @Param('id') id: string,
    @Headers() headers: Record<string, unknown>,
  ) {
    return this.certifications.removeForUser(
      getUserIdFromHeaders(headers),
      id,
    );
  }

  @Post('sync')
  sync() {
    return this.certifications.syncFromExternalApi();
  }

  @Post('sync/qnet-list')
  syncQnetList() {
    return this.certifications.syncQnetNationalQualificationList();
  }

  @Post('sync/qnet-details')
  syncQnetDetails(@Query('limit') limit?: string) {
    return this.certifications.syncQnetCertificationDetails(limit ? Number(limit) : undefined);
  }

  @Post('sync/qnet-schedules')
  syncQnetSchedules(@Query('limit') limit?: string) {
    return this.certifications.syncQnetExamSchedules(limit ? Number(limit) : undefined);
  }

  @Post('sync/qnet-schedules/:id')
  syncQnetSchedule(@Param('id') id: string) {
    return this.certifications.syncQnetExamScheduleForCertification(id);
  }

  @Post('sync/qnet-eligibilities')
  syncQnetEligibilities() {
    return this.certifications.syncQnetExamEligibilities();
  }

  @Post('sync/qnet-acquisition-stats')
  syncQnetAcquisitionStats(@Query('baseYY') baseYear?: string) {
    return this.certifications.syncQnetAcquisitionStats(
      baseYear ? Number(baseYear) : new Date().getFullYear(),
    );
  }

  @Post('sync/qnet-major-stats')
  syncQnetMajorStats(@Query('baseYY') baseYear?: string) {
    return this.certifications.syncQnetMajorStats(
      baseYear ? Number(baseYear) : new Date().getFullYear(),
    );
  }

  @Post('sync/qnet-pass-rate-stats')
  syncQnetPassRateStats(@Query('baseYY') baseYear?: string) {
    return this.certifications.syncQnetPassRateStats(
      baseYear ? Number(baseYear) : new Date().getFullYear(),
    );
  }

  @Post('sync/qnet-round-pass-rate-stats')
  syncQnetRoundPassRateStats(@Query('baseYY') baseYear?: string) {
    return this.certifications.syncQnetRoundPassRateStats(
      baseYear ? Number(baseYear) : new Date().getFullYear(),
    );
  }

  @Post('sync/tags')
  syncCertificationTags() {
    return this.certifications.syncCertificationTags();
  }
}
