import { Injectable, Logger } from '@nestjs/common';
import { IExceptionRepository } from '../interfaces/iexception.repository';
import { PrismaService } from '../../services/prisma.service';
import { ExceptionFilterDto } from 'src/modules/exception/dtos/exception.filter.dto';

@Injectable()
export class ExceptionRepository implements IExceptionRepository {
  private readonly logger = new Logger(ExceptionRepository.name);

  constructor(private prisma: PrismaService) {}

  async create(
    data: Partial<ApiTypes.Exception>,
  ): Promise<Partial<ApiTypes.Exception>> {
    const result = await this.prisma.exception.create({
      data: {
        ...data,
        statusCode: data.statusCode ?? 0, // Provide a default value for statusCode
        message: data.message ?? '', // Provide a default value for message
      },
    });

    return {
      ...result,
      path: result.path || undefined,
      stack: result.stack || undefined,
    };
  }

  async update(
    data: Partial<ApiTypes.Exception>,
  ): Promise<Partial<ApiTypes.Exception>> {
    const { id, ...updateData } = data;
    const result = await this.prisma.exception.update({
      data: updateData,
      where: { id },
    });

    return {
      ...result,
      path: result.path || undefined,
      stack: result.stack || undefined,
    };
  }

  async delete(id: string): Promise<Partial<ApiTypes.Exception>> {
    const result = await this.prisma.exception.delete({ where: { id } });

    return {
      ...result,
      path: result.path || undefined,
      stack: result.stack || undefined,
    };
  }

  async findById(id: string): Promise<Partial<ApiTypes.Exception> | null> {
    const rawData = await this.prisma.exception.findUnique({ where: { id } });

    if (!rawData) return null;

    return {
      ...rawData,
      path: rawData.path || undefined,
      stack: rawData.stack || undefined,
    };
  }

  async find(): Promise<Partial<ApiTypes.Exception>[]> {
    const rawData = await this.prisma.exception.findMany({
      orderBy: { createdAt: 'desc' },
    });

    return rawData.map((item) => ({
      ...item,
      path: item.path || undefined,
      stack: item.stack || undefined,
    }));
  }

  async findWithPagination(
    filter?: ExceptionFilterDto,
    skip = 0,
    limit = 10,
  ): Promise<[Partial<ApiTypes.Exception>[], number]> {
    this.logger.debug('findWithPagination', { filter, skip, limit });

    // Construir where com base nos filtros
    const where: any = {};

    // Filtrar por caminho
    if (filter?.path) {
      where.path = {
        contains: filter.path,
      };
    }

    // Filtrar por código de status
    if (filter?.statusCode) {
      where.statusCode = filter.statusCode;
    }

    // Filtrar por data
    if (filter?.startDate || filter?.endDate) {
      where.createdAt = {};

      if (filter.startDate) {
        where.createdAt.gte = new Date(filter.startDate);
      }

      if (filter.endDate) {
        // Ajusta para o final do dia
        const endDate = new Date(filter.endDate);
        endDate.setHours(23, 59, 59, 999);
        where.createdAt.lte = endDate;
      }
    }

    // Filtrar por termo de busca
    if (filter?.search) {
      where.OR = [
        {
          message: {
            contains: filter.search,
          },
        },
        {
          path: {
            contains: filter.search,
          },
        },
        {
          stack: {
            contains: filter.search,
          },
        },
      ];
    }

    // Construir orderBy
    let orderBy: any = { createdAt: 'desc' };

    if (filter?.sortBy) {
      orderBy = {
        [filter.sortBy]: filter.sortOrder || 'asc',
      };
    }

    // Buscar registros com paginação
    const [rawData, total] = await Promise.all([
      this.prisma.exception.findMany({
        where,
        orderBy,
        skip,
        take: limit,
      }),
      this.prisma.exception.count({ where }),
    ]);

    // Converter null para undefined para compatibilidade com o tipo Partial<ApiTypes.Exception>
    const data = rawData.map((item) => ({
      ...item,
      path: item.path || undefined,
      stack: item.stack || undefined,
    }));

    return [data, total];
  }
}
