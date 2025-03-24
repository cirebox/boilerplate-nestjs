import { Inject, Injectable, Logger } from '@nestjs/common';
import { IExceptionRepository } from 'src/modules/shared/repositories/interfaces/iexception.repository';

@Injectable()
export class FindService {
  constructor(
    @Inject('IExceptionRepository')
    private readonly exceptionRepository: IExceptionRepository,
  ) { }

  protected readonly logger = new Logger(this.constructor.name);

  async execute(): Promise<Partial<ApiTypes.Exception>[]> {
    this.logger.debug('findAll');
    return await this.exceptionRepository.find();
  }
}
