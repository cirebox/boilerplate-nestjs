export interface IExceptionRepository {
  create(
    data: Partial<ApiTypes.Exception>,
  ): Promise<Partial<ApiTypes.Exception>>;
  update(
    data: Partial<ApiTypes.Exception>,
  ): Promise<Partial<ApiTypes.Exception>>;
  delete(id: string): Promise<Partial<ApiTypes.Exception>>;
  findById(id: string): Promise<Partial<ApiTypes.Exception>>;
  find(): Promise<Partial<ApiTypes.Exception>[]>;
}
