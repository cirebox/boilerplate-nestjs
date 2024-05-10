import { ApiProperty } from "@nestjs/swagger";
import { IsBoolean, IsOptional, IsString } from "class-validator";

export class CategoryUpdateDto implements Partial<any> {
  @IsOptional()
  @IsString()
  @ApiProperty({ required: false, default: "" })
  name: string;

  @IsOptional()
  @IsString()
  @ApiProperty({ required: false, default: "" })
  subcategoryId: string;

  @IsOptional()
  @IsBoolean()
  @ApiProperty({ required: false, default: false })
  top: boolean;

  @IsOptional()
  @IsBoolean()
  @ApiProperty({ required: false, default: true })
  status?: boolean;

  @IsOptional()
  @IsString()
  @ApiProperty({ required: false, default: "" })
  userId?: string;
}
