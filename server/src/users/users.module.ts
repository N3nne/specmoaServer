import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';

import { UserEntity } from './entities/user.entity';
import { UserProfileEntity } from './entities/user-profile.entity';
import { UsersService } from './users.service';

@Module({
  imports: [TypeOrmModule.forFeature([UserEntity, UserProfileEntity])],
  providers: [UsersService],
  exports: [UsersService],
})
export class UsersModule {}
