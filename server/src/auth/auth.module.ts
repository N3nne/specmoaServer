import { Module } from '@nestjs/common';
import { APP_GUARD } from '@nestjs/core';
import { JwtModule } from '@nestjs/jwt';
import { TypeOrmModule } from '@nestjs/typeorm';
import { randomBytes } from 'crypto';

import { UsersModule } from '../users/users.module';
import { AuthController } from './auth.controller';
import { AuthService } from './auth.service';
import { AuthGuard } from './auth.guard';
import { ACCESS_TOKEN_SECONDS, AuthSessionsService } from './auth-sessions.service';
import { AuthSessionEntity } from './entities/auth-session.entity';

@Module({
  imports: [UsersModule, TypeOrmModule.forFeature([AuthSessionEntity]), JwtModule.registerAsync({
    useFactory: () => {
      const secret = process.env.JWT_SECRET;
      if (secret && secret.length < 32) throw new Error('JWT_SECRET must contain at least 32 characters.');
      if (!secret && process.env.NODE_ENV === 'production') throw new Error('JWT_SECRET is required in production.');
      return {
        secret: secret || randomBytes(32).toString('hex'),
        signOptions: { expiresIn: ACCESS_TOKEN_SECONDS, issuer: 'specmoa-api', audience: 'specmoa-app', algorithm: 'HS256' },
        verifyOptions: { issuer: 'specmoa-api', audience: 'specmoa-app', algorithms: ['HS256'] },
      };
    },
  })],
  controllers: [AuthController],
  providers: [AuthService, AuthSessionsService, { provide: APP_GUARD, useClass: AuthGuard }],
})
export class AuthModule {}
