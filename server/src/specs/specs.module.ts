import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { CertificationEntity } from '../certifications/entities/certification.entity';
import { UserSpecEntity } from './entities/user-spec.entity';
import { SpecsController } from './specs.controller';
import { SpecsService } from './specs.service';

@Module({
  imports: [TypeOrmModule.forFeature([UserSpecEntity, CertificationEntity])],
  controllers: [SpecsController], providers: [SpecsService],
})
export class SpecsModule {}
