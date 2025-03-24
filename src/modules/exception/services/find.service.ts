import { Inject, Injectable, Logger } from '@nestjs/common';
import { IExceptionRepository } from 'src/modules/shared/repositories/interfaces/iexception.repository';
import { ExceptionFilterDto } from '../dtos/exception.filter.dto';

@Injectable()
export class FindService {
  constructor(
    @Inject('IExceptionRepository')
    private readonly exceptionRepository: IExceptionRepository,
  ) {}

  private readonly logger = new Logger(FindService.name);

  async execute(filter?: ExceptionFilterDto): Promise<{
    data: Partial<ApiTypes.Exception>[];
    total: number;
    page: number;
    limit: number;
    totalPages: number;
  }> {
    this.logger.debug('findAll with filters', filter);

    const page = filter?.page || 1;
    const limit = filter?.limit || 10;
    const skip = (page - 1) * limit;

    // Vamos supor que adicionaremos essa função no repositório
    const [data, total] = await this.exceptionRepository.findWithPagination(
      filter,
      skip,
      limit,
    );

    return {
      data,
      total,
      page,
      limit,
      totalPages: Math.ceil(total / limit),
    };
  }
}
