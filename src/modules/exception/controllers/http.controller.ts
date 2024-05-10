import {
  Body,
  Controller,
  Get,
  Logger,
  Param,
  Post,
  Put,
  UseGuards,
} from '@nestjs/common';
import {
  ApiTags,
  ApiCreatedResponse,
  ApiBadRequestResponse,
  ApiUnauthorizedResponse,
  ApiNotFoundResponse,
  ApiForbiddenResponse,
  ApiBody,
  ApiResponse,
  ApiParam,
  ApiExcludeEndpoint,
  ApiBearerAuth,
} from '@nestjs/swagger';
import { FindByIdService } from '../services/find-by-id.service';
import { FindService } from '../services/find.service';
import { UpdateService } from '../services/update.service';
import { CreateService } from '../services/create.service';
import { ExceptionCreateDto } from '../dtos/exception.create.dto';
import { ExceptionUpdateDto } from '../dtos/exception.update.dto';
import { JwtGuard } from 'src/modules/shared/guards/jwt.guard';

@ApiTags('exception')
@Controller('v1/exception')
export class HttpController {
  protected logger = new Logger(HttpController.name);

  constructor(
    private readonly createService: CreateService,
    private readonly updateService: UpdateService,
    private readonly findService: FindService,
    private readonly findByIdService: FindByIdService,
  ) {}

  @ApiCreatedResponse({
    status: 201,
    description: 'Created. A new resource was successfully created.',
  })
  @ApiBadRequestResponse({
    status: 400,
    description: 'Bad Request. The request was invalid.',
  })
  @ApiUnauthorizedResponse({
    status: 401,
    description:
      'Unauthorized. The request did not include an authentication token or the authentication token was expired.',
  })
  @ApiNotFoundResponse({
    status: 402,
    description:
      'Payment Required. The requested did not include an payment accept.',
  })
  @ApiForbiddenResponse({
    status: 403,
    description:
      'Forbidden. The client did not have permission to access the requested resource.',
  })
  @UseGuards(JwtGuard)
  @ApiBearerAuth('authorization')
  @ApiBody({ type: ExceptionCreateDto, required: true })
  @ApiExcludeEndpoint()
  @Post('')
  async create(@Body() data: ExceptionCreateDto): Promise<Core.ResponseData> {
    this.logger.verbose('gRPC | CategoryService | Create');
    this.logger.verbose(`Category: ${data}`);
    const response = await this.createService.execute(data);
    return {
      code: 201,
      message: 'Categoria criada com sucesso!',
      data: response,
    };
  }

  @ApiResponse({
    status: 200,
    description: 'Ok. the request was successfully completed.',
  })
  @ApiBadRequestResponse({
    status: 400,
    description: 'Bad Request. The request was invalid.',
  })
  @ApiUnauthorizedResponse({
    status: 401,
    description:
      'Unauthorized. The request did not include an authentication token or the authentication token was expired.',
  })
  @ApiForbiddenResponse({
    status: 403,
    description:
      'Forbidden. The client did not have permission to access the requested resource.',
  })
  @ApiNotFoundResponse({
    status: 404,
    description: 'Not Found. The requested resource was not found.',
  })
  @UseGuards(JwtGuard)
  @ApiBearerAuth('authorization')
  @ApiExcludeEndpoint()
  @ApiBody({ type: ExceptionUpdateDto, required: true })
  @Put('')
  async update(@Body() data: ExceptionUpdateDto): Promise<Core.ResponseData> {
    const response = await this.updateService.execute(data);
    return {
      code: 201,
      message: 'Exceção atualizada com sucesso',
      data: response,
    };
  }

  @ApiResponse({
    status: 200,
    description: 'Ok. the request was successfully completed.',
  })
  @ApiBadRequestResponse({
    status: 400,
    description: 'Bad Request. The request was invalid.',
  })
  @ApiUnauthorizedResponse({
    status: 401,
    description:
      'Unauthorized. The request did not include an authentication token or the authentication token was expired.',
  })
  @ApiForbiddenResponse({
    status: 403,
    description:
      'Forbidden. The client did not have permission to access the requested resource.',
  })
  @ApiNotFoundResponse({
    status: 404,
    description: 'Not Found. The requested resource was not found.',
  })
  @UseGuards(JwtGuard)
  @ApiBearerAuth('authorization')
  // @ApiExcludeEndpoint()
  @ApiParam({ name: 'id', type: 'string', required: true })
  @Get('/id/:id')
  async findById(@Param('id') id: string): Promise<Core.ResponseData> {
    const response = await this.findByIdService.execute(id);
    return {
      code: 200,
      message: '',
      data: response,
    };
  }

  @ApiResponse({
    status: 200,
    description: 'Ok. the request was successfully completed.',
  })
  @ApiBadRequestResponse({
    status: 400,
    description: 'Bad Request. The request was invalid.',
  })
  @ApiUnauthorizedResponse({
    status: 401,
    description:
      'Unauthorized. The request did not include an authentication token or the authentication token was expired.',
  })
  @ApiForbiddenResponse({
    status: 403,
    description:
      'Forbidden. The client did not have permission to access the requested resource.',
  })
  @ApiNotFoundResponse({
    status: 404,
    description: 'Not Found. The requested resource was not found.',
  })
  @UseGuards(JwtGuard)
  @ApiBearerAuth('authorization')
  @Get('')
  async find(): Promise<Core.ResponseData> {
    const response = await this.findService.execute();
    return { code: 200, message: '', data: response };
  }
}
