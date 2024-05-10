import { Inject, Injectable, Logger } from '@nestjs/common';
import { IExceptionRepository } from 'src/modules/shared/repositories/interfaces/iexception.repository';

@Injectable()
export class FindService {
  constructor(
    @Inject('IExceptionRepository')
    private readonly exceptionRepository: IExceptionRepository,
  ) {}

  private readonly logger = new Logger(FindService.name);

  async execute(): Promise<any> {
    this.logger.debug('findAll');
    return await this.exceptionRepository.find();
  }
}
