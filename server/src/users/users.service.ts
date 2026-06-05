import { ConflictException, Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';

import { UserEntity } from './entities/user.entity';

@Injectable()
export class UsersService {
  constructor(
    @InjectRepository(UserEntity)
    private readonly users: Repository<UserEntity>,
  ) {}

  async findById(userId: string) {
    const user = await this.users.findOneBy({ id: userId });
    if (!user) {
      throw new NotFoundException(`User ${userId} was not found.`);
    }
    return user;
  }

  async findByEmailWithPassword(email: string) {
    return this.users
      .createQueryBuilder('user')
      .addSelect('user.passwordHash')
      .where('lower(user.email) = lower(:email)', { email })
      .getOne();
  }

  async createLocalUser(params: {
    email: string;
    displayName: string;
    passwordHash: string;
  }) {
    const existing = await this.findByEmailWithPassword(params.email);
    if (existing) {
      throw new ConflictException('이미 가입된 이메일입니다.');
    }

    return this.users.save(
      this.users.create({
        email: params.email.trim().toLowerCase(),
        displayName: params.displayName.trim(),
        authProvider: 'local',
        passwordHash: params.passwordHash,
      }),
    );
  }

  async getRequestUser(userId?: string) {
    if (userId) {
      return this.findById(userId);
    }

    return this.getOrCreateDemoUser();
  }

  private async getOrCreateDemoUser() {
    const email = 'demo@specmoa.local';
    const existing = await this.users.findOneBy({ email });

    if (existing) {
      return existing;
    }

    return this.users.save(
      this.users.create({
        email,
        displayName: 'Demo User',
        authProvider: 'demo',
      }),
    );
  }
}
