import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';
import { ValidationPipe, VersioningType } from '@nestjs/common';
import * as compression from 'compression';
import { NestExpressApplication } from '@nestjs/platform-express';
import { useContainer } from 'class-validator';
import { SWAGGER_CONFIG } from './swagger/swagger.config';
import { createSwaggerDocumentation } from 'src/swagger/swagger.create-document';
import { json } from 'express';
import * as basicAuth from 'express-basic-auth';
// import { join } from 'path';
// import { Transport } from '@nestjs/microservices';

async function bootstrap() {
  const app = await NestFactory.create<NestExpressApplication | any>(
    AppModule,
    // {
    //   logger: LoggerFactory(),
    // },
  );
  app.disable('x-powered-by');
  app.enableVersioning({
    type: VersioningType.HEADER,
    header: 'version',
  });
  app.use(json({ limit: '200mb' }));
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


  const users = process.env.DOCS_USER;
  app.use(
    "/docs*",
    basicAuth({
      challenge: true,
      users: JSON.parse(users as string)
    })
  );

  const start = process.env.NODE_ENV;
  if (start === 'development') {
    createSwaggerDocumentation('docs', app, SWAGGER_CONFIG);
  }

  app.startAllMicroservices();
  useContainer(app.select(AppModule), { fallbackOnErrors: true });

  await app.listen(process.env.HTTP_PORT || 3000);

  const url = await app.getUrl();
  console.log(`🚀 Application is running on: ${url} =>`, start);
}
bootstrap();
