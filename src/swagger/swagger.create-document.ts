import { INestApplication } from '@nestjs/common';
import { DocumentBuilder, OpenAPIObject, SwaggerModule } from '@nestjs/swagger';
import { SwaggerConfig } from './swagger.interface';

export function createSwaggerDocumentation(path: string, app: INestApplication, config: SwaggerConfig): void {

  const builder = new DocumentBuilder()
    .setTitle(config.title)
    .setDescription(config.description ?? '')
    .setVersion(config.version ?? '')
    .addServer(`http://localhost:${process.env.PORT ?? 3000}`)
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

  if (config.tags) {
    for (const tag of config.tags) {
      builder.addTag(tag);
    }
  }

  if (config.externalFilePath) builder.setExternalDoc('Export to json file', config.externalFilePath!)

  const options = builder.build();
  const document = SwaggerModule.createDocument(app, options);

  SwaggerModule.setup(
    path,
    app,
    document,
    {
      jsonDocumentUrl: config.externalFilePath, // URL do arquivo JSON da documentação
      // explorer: true, // Permite a exploração de diferentes endpoints na interface
      swaggerOptions: {
        docExpansion: 'none',           // Expande ou colapsa as seções na UI ('none', 'list', 'full')
        filter: config.filter ?? true, // Adiciona um campo de busca para filtrar os endpoints
        tagsSorter: 'alpha',            // Ordena as tags em ordem alfabética
        operationsSorter: 'alpha',      // Ordena as operações (endpoints) em ordem alfabética
        displayRequestDuration: true,   // Mostra a duração da requisição nas respostas da API
      },
    },
  );
}
