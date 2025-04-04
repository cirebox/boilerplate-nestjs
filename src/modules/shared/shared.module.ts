import { Global, Module } from '@nestjs/common';
import { PrismaService } from './services/prisma.service';
import { JwtModule, JwtService } from '@nestjs/jwt';
import { PassportModule } from '@nestjs/passport';
import { ExceptionRepository } from './repositories/prisma/exception.repository';
import { JwtStrategy } from './config/jwt.strategy';
import { MessageQueueModule } from './providers/mq/mqprovider.factory';
@Global()
@Module({
  imports: [
    PassportModule,
    JwtModule.register({
      secret: `${process.env.JWT_SECRET_KEY}`,
      signOptions: { expiresIn: '30mn' },
    }),
    MessageQueueModule.forRoot(), // Usa MQ_TYPE das variáveis de ambiente
    // ou MessageQueueModule.forRoot('kafka'), // Força um tipo específico
  ],
  providers: [
    JwtService,
    JwtStrategy,
    PrismaService,
    {
      provide: 'IExceptionRepository',
      useClass: ExceptionRepository,
    },
  ],
  exports: [
    JwtService,
    JwtStrategy,
    PrismaService,
    {
      provide: 'IExceptionRepository',
      useClass: ExceptionRepository,
    },
  ],
})
export class SharedModule {}
