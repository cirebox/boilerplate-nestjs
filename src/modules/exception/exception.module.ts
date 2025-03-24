import { Module } from '@nestjs/common';
import { HttpController } from './controllers/http.controller';
import { FindByIdService } from './services/find-by-id.service';
import { FindService } from './services/find.service';
import { CreateService } from './services/create.service';
import { UpdateService } from './services/update.service';
import { SharedModule } from '../shared/shared.module';
import { DeleteService } from './services/delete.service';

@Module({
  imports: [SharedModule],
  exports: [CreateService],
  controllers: [HttpController],
  providers: [
    FindByIdService,
    FindService,
    CreateService,
    UpdateService,
    DeleteService,
  ],
})
export class ExceptionModule {}
