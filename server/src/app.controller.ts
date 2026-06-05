import { Controller, Get } from '@nestjs/common';

@Controller()
export class AppController {
  @Get('health')
  health() {
    return {
      ok: true,
      service: 'specmoa-server',
      checkedAt: new Date().toISOString(),
    };
  }
}
