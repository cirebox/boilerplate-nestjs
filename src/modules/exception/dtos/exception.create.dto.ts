import {
  RequiredNumber,
  RequiredString,
  OptionalString,
} from '../../../core/decorators/validation.decorators';

export class ExceptionCreateDto implements Partial<ApiTypes.Exception> {
  @RequiredNumber({
    default: 500,
    description: 'Código de status HTTP',
    min: 100,
    max: 599,
  })
  statusCode: number;

  @RequiredString({
    description: 'Mensagem descritiva do erro',
    minLength: 3,
    maxLength: 255,
  })
  message: string;

  @OptionalString({
    description: 'Caminho ou rota onde o erro ocorreu',
    example: 'v1/exception',
  })
  path?: string;

  @OptionalString({
    description: 'Stack trace do erro',
    maxLength: 2000,
  })
  stack?: string;
}
