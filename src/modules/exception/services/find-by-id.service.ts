import { Inject, Injectable, Logger } from '@nestjs/common';
import { IExceptionRepository } from 'src/modules/shared/repositories/interfaces/iexception.repository';

@Injectable()
export class FindByIdService {
  constructor(
    @Inject('IExceptionRepository')
    private readonly exceptionRepository: IExceptionRepository,
  ) {}

  protected readonly logger = new Logger(this.constructor.name);

  async execute(id: string): Promise<Partial<ApiTypes.Exception>> {
    this.logger.debug('FindById', id);
    return await this.exceptionRepository.findById(id);
  }
}
