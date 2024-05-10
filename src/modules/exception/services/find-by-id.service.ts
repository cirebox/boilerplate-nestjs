import { Inject, Injectable, Logger } from '@nestjs/common';
import { IExceptionRepository } from 'src/modules/shared/repositories/interfaces/iexception.repository';

@Injectable()
export class FindByIdService {
  constructor(
    @Inject('IExceptionRepository')
    private readonly exceptionRepository: IExceptionRepository,
  ) {}

  private readonly logger = new Logger(FindByIdService.name);

  async execute(id: string): Promise<any> {
    this.logger.debug('FindById', id);
    return await this.exceptionRepository.findById(id);
  }
}
