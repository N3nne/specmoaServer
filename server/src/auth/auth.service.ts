import { Injectable, UnauthorizedException } from '@nestjs/common';
import { randomBytes, scrypt as scryptCallback, timingSafeEqual } from 'crypto';
import { promisify } from 'util';

import { UsersService } from '../users/users.service';
import { LoginDto } from './dto/login.dto';
import { RegisterDto } from './dto/register.dto';
import { RequestPasswordResetDto } from './dto/request-password-reset.dto';

const scrypt = promisify(scryptCallback);

@Injectable()
export class AuthService {
  constructor(private readonly users: UsersService) {}

  async register(dto: RegisterDto) {
    const user = await this.users.createLocalUser({
      email: dto.email,
      displayName: dto.displayName,
      passwordHash: await this.hashPassword(dto.password),
    });

    return this.toAuthResponse(user);
  }

  async login(dto: LoginDto) {
    const user = await this.users.findByEmailWithPassword(dto.email);
    if (!user?.passwordHash) {
      throw new UnauthorizedException('이메일 또는 비밀번호를 확인해주세요.');
    }

    const valid = await this.verifyPassword(dto.password, user.passwordHash);
    if (!valid) {
      throw new UnauthorizedException('이메일 또는 비밀번호를 확인해주세요.');
    }

    return this.toAuthResponse(user);
  }

  requestPasswordReset(_dto: RequestPasswordResetDto) {
    return {
      ok: true,
      message: '가입된 이메일이라면 비밀번호 재설정 안내를 보낼 예정입니다.',
    };
  }

  private async hashPassword(password: string) {
    const salt = randomBytes(16).toString('hex');
    const derived = (await scrypt(password, salt, 64)) as Buffer;
    return `${salt}:${derived.toString('hex')}`;
  }

  private async verifyPassword(password: string, storedHash: string) {
    const [salt, key] = storedHash.split(':');
    if (!salt || !key) {
      return false;
    }

    const derived = (await scrypt(password, salt, 64)) as Buffer;
    const stored = Buffer.from(key, 'hex');
    return stored.length === derived.length && timingSafeEqual(stored, derived);
  }

  private toAuthResponse(user: { id: string; email: string; displayName: string }) {
    return {
      user: {
        id: user.id,
        email: user.email,
        displayName: user.displayName,
      },
    };
  }
}
