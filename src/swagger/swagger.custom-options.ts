import { SwaggerCustomOptions } from '@nestjs/swagger';

export const customOptions: SwaggerCustomOptions = {
  swaggerOptions: {
    persistAuthorization: true,
  },
  customSiteTitle: 'Cirebox boilerplate-nestjs',
};
