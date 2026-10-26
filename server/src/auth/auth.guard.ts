import { CanActivate, ExecutionContext, Injectable, NotFoundException, UnauthorizedException } from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { JwtService } from '@nestjs/jwt';
import { isUUID } from 'class-validator';

import { VERIFIED_USER_ID } from '../common/request-user';
import { UsersService } from '../users/users.service';
import { PUBLIC_ROUTE } from './public.decorator';
import { AuthSessionsService } from './auth-sessions.service';

@Injectable()
export class AuthGuard implements CanActivate {
  constructor(
    private readonly reflector: Reflector,
    private readonly jwt: JwtService,
    private readonly users: UsersService,
    private readonly sessions: AuthSessionsService,
  ) {}

  async canActivate(context: ExecutionContext) {
    if (this.reflector.getAllAndOverride<boolean>(PUBLIC_ROUTE, [context.getHandler(), context.getClass()])) {
      return true;
    }
    const request = context.switchToHttp().getRequest();
    const authorization = request.headers.authorization;
    if (typeof authorization !== 'string' || !/^Bearer \S+$/i.test(authorization)) {
      throw new UnauthorizedException('로그인이 필요합니다.');
    }
    let payload: { sub: string; sid: string };
    try {
      payload = await this.jwt.verifyAsync<{ sub: string; sid: string }>(authorization.split(' ')[1]);
      if (!isUUID(payload.sub) || !isUUID(payload.sid)) throw new Error('Invalid session');
    } catch {
      throw new UnauthorizedException('로그인이 만료되었습니다. 다시 로그인해주세요.');
    }
    if (!await this.sessions.isActive(payload.sid, payload.sub)) {
      throw new UnauthorizedException('로그인이 만료되었습니다. 다시 로그인해주세요.');
    }
    try {
      const user = await this.users.findById(payload.sub);
      // Headers supplied over HTTP cannot contain this server-only symbol.
      request.headers[VERIFIED_USER_ID] = user.id;
      return true;
    } catch (error) {
      if (error instanceof NotFoundException) throw new UnauthorizedException('로그인이 필요합니다.');
      throw error;
    }
  }
}
