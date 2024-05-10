import { ApiProperty } from "@nestjs/swagger";
import { IsBoolean, IsDefined, IsString } from "class-validator";

export class CategoryCreateDto implements Partial<any> {
  @IsDefined()
  @IsString()
  @ApiProperty({ required: true, default: "" })
  name: string;

  @IsDefined()
  @IsString()
  @ApiProperty({ required: true, default: "" })
  subcategoryId: string;

  @IsDefined()
  @IsBoolean()
  @ApiProperty({ required: true, default: false })
  top: boolean;

  @IsDefined()
  @IsBoolean()
  @ApiProperty({ required: true, default: true })
  status: boolean;

  @IsDefined()
  @IsString()
  @ApiProperty({ required: true, default: "" })
  userId: string;
}
