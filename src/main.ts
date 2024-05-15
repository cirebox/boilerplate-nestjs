import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';
import { ValidationPipe, VersioningType } from '@nestjs/common';
import { SwaggerModule } from '@nestjs/swagger';
import * as compression from 'compression';
import { createDocument } from './swagger/swagger.create-document';
import { customOptions } from './swagger/swagger.custom-options';
import { NestExpressApplication } from '@nestjs/platform-express';
import { LoggerFactory } from './core/logger/LoggerFactory';
import { useContainer } from 'class-validator';
import { join } from 'path';
import { Transport } from '@nestjs/microservices';

async function bootstrap() {
  const app = await NestFactory.create<NestExpressApplication | any>(
    AppModule,
    {
      logger: LoggerFactory(),
    },
  );
  app.disable('x-powered-by');
  app.enableVersioning({
    type: VersioningType.HEADER,
    header: 'version',
  });
  app.enableCors();
  app.use(compression());
  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      validateCustomDecorators: true,
      transform: true,
    }),
  );

  // GRPC CONNECTION
  // app.connectMicroservice({
  //   transport: Transport.GRPC,
  //   options: {
  //     url: `0.0.0.0:${process.env.GRPC_PORT || 50051}`,
  //     package: 'cupom',
  //     protoPath: join(__dirname, 'grpc/exception.proto'),
  //   },
  // });

  // console.log(
  //   `Application grpc is running on: 0.0.0.0:${process.env.GRPC_PORT || 50051}`,
  // );

  // RMQ CONNECTION
  // app.connectMicroservice({
  //   transport: Transport.RMQ,
  //   options: {
  //     urls: [`${configService.get('RABBITMQ_URL')}`],
  //     queue: `${configService.get('RABBITMQ_QUEUE')}`,
  //     noAck: false,
  //     queueOptions: { durable: true },
  //     persistent: true,
  //   },
  // });

  //  app.useWebSocketAdapter(new IoAdapter(app));

  SwaggerModule.setup('v1/doc', app, createDocument(app), customOptions);
  app.startAllMicroservices();
  useContainer(app.select(AppModule), { fallbackOnErrors: true });

  await app.listen(process.env.HTTP_PORT || 3000);

  const url = await app.getUrl();
  console.log(`Application is running on: ${url}`);
  console.log(`Swagger available at ${url}/v1/doc`);
}
bootstrap();
