/* eslint-disable @typescript-eslint/no-unused-vars */
import {
  ExecutionContext,
  Injectable,
  Logger,
  CanActivate,
} from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';

@Injectable()
export class JwtGuard implements CanActivate {
  protected logger = new Logger(JwtGuard.name);
  constructor(private readonly jwtService: JwtService) {}

  async canActivate(context: ExecutionContext) {
    //Liberar tudo por enquanto
    return true;

    // const request = context.switchToHttp().getRequest();
    // const token = this.extractTokenFromHeader(request);
    // if (!token) {
    //   throw new UnauthorizedException();
    // }
    // try {
    //   const payload = await this.jwtService.verifyAsync(
    //     token,
    //     {
    //       secret: jwtConstants.secret
    //     }
    //   );
    //   this.logger.debug("[USER]", payload)
    //   request['user'] = payload;
    // } catch {
    //   throw new UnauthorizedException();
    // }
    // return true;
  }

  private extractTokenFromHeader(request: any): string | undefined {
    const [type, token] = request.headers?.authorization?.split(' ') ?? [];
    return type === 'Bearer' ? token : undefined;
  }
}
