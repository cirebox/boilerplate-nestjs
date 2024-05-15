import { Inject, Injectable, Logger } from '@nestjs/common';
import { ExceptionCreateDto } from '../dtos/exception.create.dto';
import { IExceptionRepository } from 'src/modules/shared/repositories/interfaces/iexception.repository';

@Injectable()
export class CreateService {
  constructor(
    @Inject('IExceptionRepository')
    private readonly exceptionRepository: IExceptionRepository,
  ) {}

  private readonly logger = new Logger(CreateService.name);

  async execute(
    data: ExceptionCreateDto,
  ): Promise<Partial<ApiTypes.Exception>> {
    this.logger.debug('Create', data);
    return await this.exceptionRepository.create(data);
  }
}
