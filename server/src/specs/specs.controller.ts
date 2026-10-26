import { Body, Controller, Delete, Get, Headers, Param, ParseUUIDPipe, Patch, Post, Query } from '@nestjs/common';
import { getUserIdFromHeaders } from '../common/request-user';
import { CreateSpecDto, ListSpecsDto, UpdateSpecDto } from './dto/spec.dto';
import { SpecsService } from './specs.service';

@Controller('specs')
export class SpecsController {
  constructor(private readonly specs: SpecsService) {}

  @Get()
  list(@Headers() headers: Record<string, unknown>, @Query() query: ListSpecsDto) {
    return this.specs.list(getUserIdFromHeaders(headers), query);
  }

  @Get('summary')
  summary(@Headers() headers: Record<string, unknown>) {
    return this.specs.summary(getUserIdFromHeaders(headers));
  }

  @Get(':id')
  find(@Headers() headers: Record<string, unknown>, @Param('id', ParseUUIDPipe) id: string) {
    return this.specs.find(getUserIdFromHeaders(headers), id);
  }

  @Post()
  create(@Headers() headers: Record<string, unknown>, @Body() dto: CreateSpecDto) {
    return this.specs.create(getUserIdFromHeaders(headers), dto);
  }

  @Patch(':id')
  update(@Headers() headers: Record<string, unknown>, @Param('id', ParseUUIDPipe) id: string, @Body() dto: UpdateSpecDto) {
    return this.specs.update(getUserIdFromHeaders(headers), id, dto);
  }

  @Delete(':id')
  remove(@Headers() headers: Record<string, unknown>, @Param('id', ParseUUIDPipe) id: string) {
    return this.specs.remove(getUserIdFromHeaders(headers), id);
  }
}
