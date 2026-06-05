import { Controller, Get, Headers } from '@nestjs/common';

import { getUserIdFromHeaders } from '../common/request-user';
import { HomeService } from './home.service';

@Controller('home')
export class HomeController {
  constructor(private readonly home: HomeService) {}

  @Get()
  getHome(@Headers() headers: Record<string, unknown>) {
    return this.home.getHome(getUserIdFromHeaders(headers));
  }
}
