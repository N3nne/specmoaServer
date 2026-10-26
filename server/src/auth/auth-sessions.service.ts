import { Injectable, UnauthorizedException } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { InjectRepository } from '@nestjs/typeorm';
import { createHash, randomBytes, randomUUID, timingSafeEqual } from 'crypto';
import { IsNull, MoreThan, Repository } from 'typeorm';

import { UserEntity } from '../users/entities/user.entity';
import { AuthSessionEntity } from './entities/auth-session.entity';

export const ACCESS_TOKEN_SECONDS = 15 * 60;
const SESSION_MILLISECONDS = 30 * 24 * 60 * 60 * 1000;
type SessionUser = { id: string; email: string; displayName: string };

@Injectable()
export class AuthSessionsService {
  constructor(
    @InjectRepository(AuthSessionEntity) private readonly sessions: Repository<AuthSessionEntity>,
    private readonly jwt: JwtService,
  ) {}

  async create(user: SessionUser) {
    const id = randomUUID();
    const refreshToken = this.newToken(id);
    const session = this.sessions.create({
      id, userId: user.id, tokenHash: this.hash(refreshToken),
      expiresAt: new Date(Date.now() + SESSION_MILLISECONDS), revokedAt: null,
    });
    const response = await this.response(user, session, refreshToken);
    await this.sessions.save(session);
    return response;
  }

  async refresh(refreshToken: string) {
    return this.sessions.manager.transaction(async manager => {
      const repository = manager.getRepository(AuthSessionEntity);
      // A row lock ensures a refresh token can be consumed only once, even across server instances.
      const session = await repository.createQueryBuilder('session')
        .addSelect('session.tokenHash').setLock('pessimistic_write')
        .where('session.id = :id', { id: refreshToken.split('.')[0] }).getOne();
      if (!session || session.revokedAt || session.expiresAt.getTime() <= Date.now() ||
          !this.matches(refreshToken, session.tokenHash)) {
        throw new UnauthorizedException('로그인이 만료되었습니다. 다시 로그인해주세요.');
      }
      const user = await manager.getRepository(UserEntity).findOneBy({ id: session.userId });
      if (!user) throw new UnauthorizedException('로그인이 필요합니다.');
      const nextToken = this.newToken(session.id);
      const response = await this.response(user, session, nextToken);
      await repository.update(session.id, { tokenHash: this.hash(nextToken) });
      return response;
    });
  }

  async revoke(refreshToken: string) {
    await this.sessions.update({
      id: refreshToken.split('.')[0], tokenHash: this.hash(refreshToken), revokedAt: IsNull(),
    }, { revokedAt: new Date() });
    return { ok: true };
  }

  async isActive(id: string, userId: string) {
    return this.sessions.existsBy({ id, userId, revokedAt: IsNull(), expiresAt: MoreThan(new Date()) });
  }

  private newToken(id: string) {
    return `${id}.${randomBytes(32).toString('base64url')}`;
  }

  private hash(token: string) {
    return createHash('sha256').update(token).digest('hex');
  }

  private matches(token: string, stored: string) {
    const actual = Buffer.from(this.hash(token), 'hex');
    const expected = Buffer.from(stored, 'hex');
    return actual.length === expected.length && timingSafeEqual(actual, expected);
  }

  private async response(user: SessionUser, session: AuthSessionEntity, refreshToken: string) {
    return {
      accessToken: await this.jwt.signAsync({ sub: user.id, sid: session.id }),
      expiresIn: ACCESS_TOKEN_SECONDS,
      refreshToken,
      refreshExpiresAt: session.expiresAt.toISOString(),
      user: { id: user.id, email: user.email, displayName: user.displayName },
    };
  }
}
