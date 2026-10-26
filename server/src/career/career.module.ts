import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { UserSpecEntity } from '../specs/entities/user-spec.entity';
import { UserProfileEntity } from '../users/entities/user-profile.entity';
import { CareerController } from './career.controller';
import { CareerService } from './career.service';

@Module({
  imports: [TypeOrmModule.forFeature([UserProfileEntity, UserSpecEntity])],
  controllers: [CareerController],
  providers: [CareerService],
})
export class CareerModule {}
