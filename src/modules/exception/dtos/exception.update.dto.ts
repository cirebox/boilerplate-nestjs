import {
  OptionalNumber,
  OptionalString,
  RequiredUUID,
} from '../../../core/decorators/validation.decorators';

export class ExceptionUpdateDto implements Partial<ApiTypes.Exception> {
  @RequiredUUID({
    description: 'ID único da exceção',
  })
  id: string;

  @OptionalNumber({
    description: 'Código de status HTTP',
    min: 100,
    max: 599,
  })
  statusCode?: number;

  @OptionalString({
    description: 'Mensagem descritiva do erro',
    minLength: 3,
    maxLength: 255,
  })
  message?: string;

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
