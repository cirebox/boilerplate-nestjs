export interface IExceptionRepository {
  create(data: any): Promise<any>;
  update(data: any): Promise<any>;
  findById(id: string): Promise<any>;
  find(): Promise<any[]>;
}
