import { Module } from '@nestjs/common';
import { SharedModule } from './modules/shared/shared.module';
import { APP_FILTER, APP_GUARD, APP_INTERCEPTOR, APP_PIPE } from '@nestjs/core';
import { ExceptionFilterHttp } from './core/filters/execption-filter-http.filter';
import { JwtGuard } from './modules/shared/guards/jwt.guard';
import { RolesGuard } from './modules/shared/guards/roles.guard';
import { HealthModule } from './modules/health/health.module';
import { ExceptionModule } from './modules/exception/exception.module';
import { ConfigModule } from '@nestjs/config';
import { AppController } from './app.controller';
import { CustomValidationPipe } from './core/pipes/validation.pipe';
import { ValidationInterceptor } from './core/interceptors/validation.interceptor';

@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true, // Torna as configurações globais (opcional)
    }),
    SharedModule,
    HealthModule,
    ExceptionModule,
  ],
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
    {
      provide: APP_PIPE,
      useClass: CustomValidationPipe,
    },
    {
      provide: APP_INTERCEPTOR,
      useClass: ValidationInterceptor,
    },
  ],
  controllers: [AppController],
})
export class AppModule {}
