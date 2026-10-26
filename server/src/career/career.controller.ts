import { Body, Controller, Get, Header, Headers, Patch, Query } from '@nestjs/common';
import { getUserIdFromHeaders } from '../common/request-user';
import { CareerService } from './career.service';
import { CareerQueryDto, UpdateCareerPreferencesDto } from './dto/update-career-preferences.dto';

@Controller('career')
export class CareerController {
  constructor(private readonly career: CareerService) {}

  @Get('occupations')
  occupations(@Query() _query: CareerQueryDto) {
    return this.career.occupations();
  }

  @Get('preferences')
  @Header('Cache-Control', 'no-store')
  preferences(@Headers() headers: Record<string, unknown>, @Query() _query: CareerQueryDto) {
    return this.career.preferences(getUserIdFromHeaders(headers));
  }

  @Patch('preferences')
  @Header('Cache-Control', 'no-store')
  updatePreferences(@Headers() headers: Record<string, unknown>, @Body() dto: UpdateCareerPreferencesDto, @Query() _query: CareerQueryDto) {
    return this.career.updatePreferences(getUserIdFromHeaders(headers), dto);
  }

  @Get('analysis-context')
  @Header('Cache-Control', 'no-store')
  analysisContext(@Headers() headers: Record<string, unknown>, @Query() _query: CareerQueryDto) {
    return this.career.analysisContext(getUserIdFromHeaders(headers));
  }
}
