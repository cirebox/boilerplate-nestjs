import {
  Catch,
  ExceptionFilter,
  ArgumentsHost,
  HttpStatus,
  HttpException,
} from '@nestjs/common';
import { FastifyReply } from 'fastify';

@Catch(Error)
export class HealthCheckExceptionFilter implements ExceptionFilter {
  catch(exception: HttpException, host: ArgumentsHost) {
    const ctx = host.switchToHttp();
    const response = ctx.getResponse<FastifyReply>();
    const status =
      exception instanceof HttpException
        ? exception.getStatus()
        : HttpStatus.INTERNAL_SERVER_ERROR;

    // Com Fastify, você usa .code() e .send()
    response.code(status).send(
      exception instanceof HttpException
        ? exception.getResponse()
        : {
            statusCode: status,
            error: 'Internal Server Error',
            message: 'Unknown error',
          },
    );
  }
}
