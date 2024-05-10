import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';
import { ValidationPipe } from '@nestjs/common';
import { SwaggerModule } from '@nestjs/swagger';
import * as compression from 'compression';
import { createDocument } from './swagger/swagger.create-document';
import { customOptions } from './swagger/swagger.custom-options';
import { NestExpressApplication } from '@nestjs/platform-express';
import { LoggerFactory } from './core/logger/LoggerFactory';

async function bootstrap() {
  const app = await NestFactory.create<NestExpressApplication | any>(
    AppModule,
    {
      logger: LoggerFactory(),
    },
  );

  SwaggerModule.setup('v1/doc', app, createDocument(app), customOptions);

  app.enableCors();
  app.disable('x-powered-by');
  app.use(compression());
  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      validateCustomDecorators: true,
      transform: true,
    }),
  );

  // RMQ CONNECTION
  // app.connectMicroservice({
  //   transport: Transport.RMQ,
  //   options: {
  //     urls: [`${configService.get('RABBITMQ_URL')}`],
  //     queue: `${configService.get('RABBITMQ_QUEUE')}`,
  //     queueOptions: { durable: true },
  //     persistent: true,
  //   },
  // });

  //  app.useWebSocketAdapter(new IoAdapter(app));

  app.startAllMicroservices();
  await app.listen(process.env.PORT || 3000);
  const url = await app.getUrl();
  console.log(`Application is running on: ${url}`);
  console.log(`Swagger available at ${url}/v1/doc`);
}
bootstrap();
