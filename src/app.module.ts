import { Module } from '@nestjs/common';
import { SharedModule } from './modules/shared/shared.module';
import { APP_FILTER, APP_GUARD } from '@nestjs/core';
import { ExceptionFilterHttp } from './core/filters/execption-filter-http.filter';
import { JwtGuard } from './modules/shared/guards/jwt.guard';
import { RolesGuard } from './modules/shared/guards/roles.guard';
import { HealthModule } from './modules/health/health.module';
import { ExceptionModule } from './modules/exception/exception.module';

@Module({
  imports: [SharedModule, HealthModule, ExceptionModule],
  providers: [
    {
      provide: APP_FILTER,
      useClass: ExceptionFilterHttp,
    },
    {
      provide: APP_GUARD,
      useClass: JwtGuard,
    },
    {
      provide: APP_GUARD,
      useClass: RolesGuard,
    },
  ],
})
export class AppModule {}
