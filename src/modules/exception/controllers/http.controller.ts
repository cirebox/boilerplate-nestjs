import {
  Body,
  Controller,
  Delete,
  Get,
  HttpStatus,
  Logger,
  Param,
  Post,
  Put,
  UseGuards,
  HttpCode,
} from '@nestjs/common';
import {
  ApiTags,
  ApiBody,
  ApiParam,
  ApiExcludeEndpoint,
  ApiBearerAuth,
  ApiOperation,
} from '@nestjs/swagger';
import { FindByIdService } from '../services/find-by-id.service';
import { FindService } from '../services/find.service';
import { UpdateService } from '../services/update.service';
import { CreateService } from '../services/create.service';
import { ExceptionCreateDto } from '../dtos/exception.create.dto';
import { ExceptionUpdateDto } from '../dtos/exception.update.dto';
import { JwtGuard } from 'src/modules/shared/guards/jwt.guard';
import { DeleteService } from '../services/delete.service';

@ApiTags('Exception')
@Controller('v1/exception')
export class HttpController {
  protected logger = new Logger(HttpController.name);

  constructor(
    private readonly createService: CreateService,
    private readonly updateService: UpdateService,
    private readonly findService: FindService,
    private readonly findByIdService: FindByIdService,
    private readonly deleteService: DeleteService,
  ) {}

  // @ApiExcludeEndpoint()
  @Post('')
  @UseGuards(JwtGuard)
  @ApiBearerAuth('JWT')
  @ApiBody({ type: ExceptionCreateDto, required: true })
  @HttpCode(HttpStatus.CREATED)
  @ApiOperation({ summary: 'Criar uma nova exceção' })
  async create(@Body() data: ExceptionCreateDto): Promise<Core.ResponseData> {
    this.logger.verbose('gRPC | CategoryService | Create');
    this.logger.verbose(`Category: ${JSON.stringify(data)}`);
    const response = await this.createService.execute(data);
    return {
      code: 201,
      message: 'Registro criado com sucesso!',
      data: response,
    };
  }

  @ApiExcludeEndpoint()
  @Put('')
  @UseGuards(JwtGuard)
  @ApiBearerAuth('JWT')
  @ApiBody({ type: ExceptionUpdateDto, required: true })
  @HttpCode(HttpStatus.CREATED)
  @ApiOperation({ summary: 'Atualiza uma exceção' })
  async update(@Body() data: ExceptionUpdateDto): Promise<Core.ResponseData> {
    const response = await this.updateService.execute(data);
    return {
      code: 201,
      message: 'Registro atualizado com sucesso',
      data: response,
    };
  }

  @Delete(':id')
  @UseGuards(JwtGuard)
  @ApiBearerAuth('JWT')
  @ApiParam({ name: 'id', type: 'string', required: true })
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Remove uma exceção' })
  async deleteById(@Param('id') id: string): Promise<Core.ResponseData> {
    const response = await this.deleteService.execute(id);
    return {
      code: HttpStatus.OK,
      message: 'Removido com sucesso!',
      data: response,
    };
  }

  @Get('/id/:id')
  @UseGuards(JwtGuard)
  @ApiBearerAuth('JWT')
  @ApiParam({ name: 'id', type: 'string', required: true })
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Buscar exceção por ID' })
  async findById(@Param('id') id: string): Promise<Core.ResponseData> {
    const response = await this.findByIdService.execute(id);
    return {
      code: HttpStatus.OK,
      message: 'Registro encontrado com sucesso!',
      data: response,
    };
  }

  @Get('')
  @UseGuards(JwtGuard)
  @ApiBearerAuth('JWT')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Buscar todas as exceção' })
  async find(): Promise<Core.ResponseData> {
    const response = await this.findService.execute();
    return { code: HttpStatus.OK, message: '', data: response };
  }
}
