import { Body, Controller, Header, Post } from '@nestjs/common';

import { AuthService } from './auth.service';
import { AuthSessionsService } from './auth-sessions.service';
import { LoginDto } from './dto/login.dto';
import { RegisterDto } from './dto/register.dto';
import { RequestPasswordResetDto } from './dto/request-password-reset.dto';
import { Public } from './public.decorator';
import { RefreshTokenDto } from './dto/refresh-token.dto';

@Controller('auth')
export class AuthController {
  constructor(private readonly auth: AuthService, private readonly sessions: AuthSessionsService) {}

  @Public()
  @Post('register')
  @Header('Cache-Control', 'no-store')
  register(@Body() dto: RegisterDto) {
    return this.auth.register(dto);
  }

  @Public()
  @Post('login')
  @Header('Cache-Control', 'no-store')
  login(@Body() dto: LoginDto) {
    return this.auth.login(dto);
  }

  @Public()
  @Post('refresh')
  @Header('Cache-Control', 'no-store')
  refresh(@Body() dto: RefreshTokenDto) {
    return this.sessions.refresh(dto.refreshToken);
  }

  @Public()
  @Post('logout')
  @Header('Cache-Control', 'no-store')
  logout(@Body() dto: RefreshTokenDto) {
    return this.sessions.revoke(dto.refreshToken);
  }

  @Public()
  @Post('password-reset')
  requestPasswordReset(@Body() dto: RequestPasswordResetDto) {
    return this.auth.requestPasswordReset(dto);
  }
}
