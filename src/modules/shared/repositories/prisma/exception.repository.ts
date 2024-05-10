import { Injectable } from '@nestjs/common';
import { IExceptionRepository } from '../interfaces/iexception.repository';
import { PrismaService } from '../../services/prisma.service';

@Injectable()
export class ExceptionRepository implements IExceptionRepository {
  constructor(private prisma: PrismaService) {}
  create(data: any): Promise<any> {
    return this.prisma.exception.create({ data });
  }
  update(data: any): Promise<any> {
    return this.prisma.exception.update({ data, where: { id: data.id } });
  }
  findById(id: string): Promise<any> {
    return this.prisma.exception.findUnique({ where: { id } });
  }
  find(): Promise<any[]> {
    return this.prisma.exception.findMany();
  }
}
