import { ExceptionFilterDto } from 'src/modules/exception/dtos/exception.filter.dto';

export interface IExceptionRepository {
  create(
    data: Partial<ApiTypes.Exception>,
  ): Promise<Partial<ApiTypes.Exception>>;

  update(
    data: Partial<ApiTypes.Exception>,
  ): Promise<Partial<ApiTypes.Exception>>;

  delete(id: string): Promise<Partial<ApiTypes.Exception>>;

  findById(id: string): Promise<Partial<ApiTypes.Exception> | null>;

  find(): Promise<Partial<ApiTypes.Exception>[]>;

  findWithPagination(
    filter?: ExceptionFilterDto,
    skip?: number,
    limit?: number,
  ): Promise<[Partial<ApiTypes.Exception>[], number]>;
}
