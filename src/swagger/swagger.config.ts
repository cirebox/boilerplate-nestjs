import { SwaggerConfig } from './swagger.interface';

export const SWAGGER_CONFIG: SwaggerConfig = {
  title: 'Boilerplate-nestjs',
  description: '',
  version: '1.0',
  externalFilePath: 'docs/json',
  filter: true,
  tags: ['health', 'exception'],
};
