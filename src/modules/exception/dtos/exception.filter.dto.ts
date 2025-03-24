import { ApiProperty } from '@nestjs/swagger';
import { IsOptional, IsString, IsInt, Min, Max } from 'class-validator';
import { Transform, Type } from 'class-transformer';
import { BaseFilterDto } from '../../../core/dtos/base-filter.dto';

export class ExceptionFilterDto extends BaseFilterDto {
  @ApiProperty({
    required: false,
    description: 'Filtrar por caminho específico',
  })
  @IsOptional()
  @IsString()
  @Transform(({ value }) => value?.trim())
  path?: string;

  @ApiProperty({
    required: false,
    type: Number,
    description: 'Filtrar por código de status HTTP',
    minimum: 100,
    maximum: 599,
  })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(100)
  @Max(599)
  statusCode?: number;

  @ApiProperty({
    required: false,
    type: String,
    description: 'Data inicial (formato: YYYY-MM-DD)',
  })
  @IsOptional()
  @IsString()
  @Transform(({ value }) => value?.trim())
  startDate?: string;

  @ApiProperty({
    required: false,
    type: String,
    description: 'Data final (formato: YYYY-MM-DD)',
  })
  @IsOptional()
  @IsString()
  @Transform(({ value }) => value?.trim())
  endDate?: string;
}
