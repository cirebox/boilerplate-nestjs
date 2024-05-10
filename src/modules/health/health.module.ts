import { Module } from '@nestjs/common';
import { HealthController } from './health.controller';
import { TerminusModule } from '@nestjs/terminus';
import { ApiHealthIndicator } from './health.indicator';
import { SharedModule } from '../shared/shared.module';

@Module({
  imports: [TerminusModule, SharedModule],
  controllers: [HealthController],
  providers: [ApiHealthIndicator],
})
export class HealthModule {}
