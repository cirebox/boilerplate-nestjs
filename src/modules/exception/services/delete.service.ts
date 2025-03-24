import { Inject, Injectable, Logger } from '@nestjs/common';
import { IExceptionRepository } from 'src/modules/shared/repositories/interfaces/iexception.repository';

@Injectable()
export class DeleteService {
  constructor(
    @Inject('IExceptionRepository')
    private readonly exceptionRepository: IExceptionRepository,
  ) {}

  protected readonly logger = new Logger(this.constructor.name);

  async execute(id: string): Promise<Partial<ApiTypes.Exception>> {
    this.logger.debug('DeleteById', id);
    return await this.exceptionRepository.delete(id);
  }
}
