import { Controller, Get, UseFilters } from '@nestjs/common';
import {
  HealthCheck,
  HealthCheckService,
  MicroserviceHealthIndicator,
  PrismaHealthIndicator,
} from '@nestjs/terminus';
import { ApiHealthIndicator } from './health.indicator';
import { Transport } from '@nestjs/microservices';
import { ConfigService } from '@nestjs/config';
import { HealthCheckExceptionFilter } from './health-check-exception-filter';
import { PrismaService } from '../shared/services/prisma.service';

@Controller('health')
export class HealthController {
  public constructor(
    private health: HealthCheckService,
    private api: ApiHealthIndicator,
    private prisma: PrismaHealthIndicator,
    private readonly prismaService: PrismaService,
    private microservice: MicroserviceHealthIndicator,
  ) {}

  @Get()
  @UseFilters(HealthCheckExceptionFilter)
  @HealthCheck()
  public check() {
    const configService = new ConfigService();
    return this.health.check([
      () => this.api.pingCheck('api'),
      () => this.prisma.pingCheck('prisma', this.prismaService),
      () =>
        this.microservice.pingCheck('message_broker', {
          transport: Transport.RMQ,
          options: {
            urls: `${configService.get('RABBITMQ_URL')}`,
            queueOptions: { durable: true },
            persistent: true,
          },
        }),
    ]);
  }
}
