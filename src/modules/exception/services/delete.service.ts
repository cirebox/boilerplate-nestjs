import { Inject, Injectable, Logger } from '@nestjs/common';
import { IExceptionRepository } from 'src/modules/shared/repositories/interfaces/iexception.repository';

@Injectable()
export class DeleteService {
  constructor(
    @Inject('IExceptionRepository')
    private readonly exceptionRepository: IExceptionRepository,
  ) {}

  private readonly logger = new Logger(DeleteService.name);

  async execute(id: string): Promise<any> {
    this.logger.debug('DeleteById', id);
    return await this.exceptionRepository.delete(id);
  }
}
