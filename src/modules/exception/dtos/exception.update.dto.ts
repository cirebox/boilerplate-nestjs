import { ApiProperty } from '@nestjs/swagger';
import { IsDefined, IsString, IsNumber } from 'class-validator';

export class ExceptionUpdateDto implements Partial<ApiTypes.Exception> {
  @IsDefined()
  @IsString()
  @ApiProperty({ required: true, default: '' })
  id: string;

  @IsNumber()
  @ApiProperty({ required: false, default: 500 })
  statusCode?: number;

  @IsString()
  @ApiProperty({ required: false, default: '' })
  message?: string;

  @IsString()
  @ApiProperty({ required: false, default: 'v1/exception' })
  path?: string;

  @IsString()
  @ApiProperty({ required: false, default: '' })
  stack?: string;
}
