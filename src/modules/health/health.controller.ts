import { Controller, Get, UseFilters } from '@nestjs/common';
import {
  HealthCheck,
  HealthCheckService,
  MicroserviceHealthIndicator,
  PrismaHealthIndicator,
  DiskHealthIndicator,
  MemoryHealthIndicator,
  HttpHealthIndicator,
} from '@nestjs/terminus';
import { Transport } from '@nestjs/microservices';
import { HealthCheckExceptionFilter } from './health-check-exception-filter';
import { PrismaService } from '../shared/services/prisma.service';

@Controller('health')
export class HealthController {
  public constructor(
    private health: HealthCheckService,
    private http: HttpHealthIndicator,
    private readonly prisma: PrismaHealthIndicator,
    private readonly prismaService: PrismaService,
    private readonly microservice: MicroserviceHealthIndicator,
    private readonly disk: DiskHealthIndicator,
    private readonly memory: MemoryHealthIndicator,
  ) {}

  @Get()
  @UseFilters(HealthCheckExceptionFilter)
  @HealthCheck()
  public check() {
    return this.health.check([
      // Verificações de serviços essenciais
      () => this.http.pingCheck('api', 'http://localhost:3000'), // Replace with the actual URL or variable
      () => this.prisma.pingCheck('prisma', this.prismaService),

      // Verificação de Redis/BullMQ (se ativo)
      async () => {
        try {
          const result = await this.microservice.pingCheck('redis_bullmq', {
            transport: Transport.REDIS,
            options: {
              host: process.env.REDIS_HOST || 'localhost',
              port: parseInt(process.env.REDIS_PORT || '6379'),
              password: process.env.REDIS_PASSWORD,
              db: parseInt(process.env.REDIS_DB || '0'),
            },
          });
          return result;
        } catch {
          // Se Redis não é essencial, você pode retornar um status "up" mesmo quando falha
          // Caso contrário, permita que o erro seja lançado para causar falha no health check
          return {
            redis_bullmq: {
              status: 'up',
              message: 'Optional: Redis unavailable but service can function',
            },
          };
        }
      },

      // Verificações de recursos do sistema
      () =>
        this.disk.checkStorage('storage', {
          path: '/',
          threshold: 250 * 1024 * 1024 * 1024, // 250GB em bytes
        }),
      () => this.memory.checkHeap('memory_heap', 150 * 1024 * 1024), // 150MB em bytes
      () => this.memory.checkRSS('memory_rss', 300 * 1024 * 1024), // 300MB em bytes

      // Verificações de dependências externas (se houver)
      // Exemplo: API externa que seu serviço depende
      async () => {
        if (process.env.EXTERNAL_API_URL) {
          return this.http.pingCheck(
            'external_api',
            process.env.EXTERNAL_API_URL,
          );
        }
        return { external_api: { status: 'up', message: 'Not configured' } };
      },

      // Versão do aplicativo
      () => {
        return {
          version: {
            status: 'up',
            version: process.env.npm_package_version || '1.0.0',
            environment: process.env.NODE_ENV || 'development',
          },
        };
      },

      // Informações de tempo de atividade
      () => {
        const uptimeSeconds = process.uptime();
        const days = Math.floor(uptimeSeconds / 86400);
        const hours = Math.floor((uptimeSeconds % 86400) / 3600);
        const minutes = Math.floor((uptimeSeconds % 3600) / 60);
        const seconds = Math.floor(uptimeSeconds % 60);

        return {
          uptime: {
            status: 'up',
            uptime: `${days}d ${hours}h ${minutes}m ${seconds}s`,
            uptimeSeconds,
          },
        };
      },
    ]);
  }

  // Endpoint adicional para informações mais detalhadas
  @Get('/details')
  @UseFilters(HealthCheckExceptionFilter)
  @HealthCheck()
  public async detailedHealth() {
    const basicHealth = await this.check();

    // Adicionar métricas mais detalhadas
    return {
      ...basicHealth,
      metrics: {
        processInfo: {
          memoryUsage: process.memoryUsage(),
          cpuUsage: process.cpuUsage(),
          pid: process.pid,
          nodejsVersion: process.version,
          platform: process.platform,
          arch: process.arch,
        },
        environment: {
          nodeEnv: process.env.NODE_ENV,
          httpPort: process.env.HTTP_PORT,
        },
      },
    };
  }
}
