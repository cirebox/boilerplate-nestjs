import { Inject, Injectable, Logger } from '@nestjs/common';
import { ExceptionUpdateDto } from '../dtos/exception.update.dto';
import { IExceptionRepository } from 'src/modules/shared/repositories/interfaces/iexception.repository';

@Injectable()
export class UpdateService {
  constructor(
    @Inject('IExceptionRepository')
    private readonly exceptionRepository: IExceptionRepository,
  ) {}

  protected readonly logger = new Logger(this.constructor.name);

  async execute(
    data: ExceptionUpdateDto,
  ): Promise<Partial<ApiTypes.Exception>> {
    this.logger.debug('Update', data);
    return await this.exceptionRepository.update(data);
  }
}
