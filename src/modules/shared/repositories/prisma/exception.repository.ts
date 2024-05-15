import { Injectable } from '@nestjs/common';
import { IExceptionRepository } from '../interfaces/iexception.repository';
import { PrismaService } from '../../services/prisma.service';

@Injectable()
export class ExceptionRepository implements IExceptionRepository {
  constructor(private prisma: PrismaService) {}

  async create(data: any): Promise<any> {
    return await this.prisma.exception.create({ data });
  }

  async update(data: any): Promise<any> {
    return await this.prisma.exception.update({ data, where: { id: data.id } });
  }

  async delete(id: string): Promise<any> {
    return await this.prisma.exception.delete({ where: { id } });
  }

  async findById(id: string): Promise<any> {
    return await this.prisma.exception.findUnique({ where: { id } });
  }

  async find(): Promise<any[]> {
    return await this.prisma.exception.findMany();
  }
}
