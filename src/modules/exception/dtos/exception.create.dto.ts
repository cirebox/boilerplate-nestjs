import { ApiProperty } from '@nestjs/swagger';
import { IsDefined, IsString, IsNumber } from 'class-validator';

export class ExceptionCreateDto implements Partial<any> {
  @IsDefined()
  @IsNumber()
  @ApiProperty({ required: true, default: 500 })
  statusCode: number;

  @IsDefined()
  @IsString()
  @ApiProperty({ required: true, default: '' })
  message: string;

  @IsString()
  @ApiProperty({ required: false, default: 'v1/exception' })
  path?: string;

  @IsString()
  @ApiProperty({ required: false, default: '' })
  stack?: string;
}
