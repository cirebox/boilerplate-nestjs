import { Module } from '@nestjs/common';
import { HealthController } from './health.controller';
import { TerminusModule } from '@nestjs/terminus';
import { SharedModule } from '../shared/shared.module';
import { HttpModule } from '@nestjs/axios';

@Module({
  imports: [TerminusModule, HttpModule, SharedModule],
  controllers: [HealthController],
})
export class HealthModule {}
