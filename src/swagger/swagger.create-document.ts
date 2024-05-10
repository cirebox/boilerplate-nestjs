import { INestApplication } from '@nestjs/common';
import { DocumentBuilder, OpenAPIObject, SwaggerModule } from '@nestjs/swagger';
import { SWAGGER_CONFIG } from './swagger.config';

export function createDocument(app: INestApplication): OpenAPIObject {
  const builder = new DocumentBuilder()
    .setTitle(SWAGGER_CONFIG.title)
    .setDescription(SWAGGER_CONFIG.description)
    .setVersion(SWAGGER_CONFIG.version)
    .addServer(`http://localhost:${process.env.PORT || 3000}`)
    .addBearerAuth(
      {
        type: 'apiKey',
        scheme: 'Bearer',
        bearerFormat: 'JWT',
        name: 'authorization',
        description: 'Enter JWT token',
        in: 'header',
      },
      'authorization',
    );
  for (const tag of SWAGGER_CONFIG.tags) {
    builder.addTag(tag);
  }
  const options = builder.build();
  return SwaggerModule.createDocument(app, options);
}
