import { TestingModule } from '@nestjs/testing/testing-module';
import { Test } from '@nestjs/testing';
import { ExceptionUpdateDto } from '../dtos/exception.update.dto';
import { UpdateService } from '../services/update.service';

describe('UpdateService', () => {
  let updateService: UpdateService;

  const exceptionRepositoryMock = {
    update: jest.fn(),
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        UpdateService,
        {
          provide: 'IExceptionRepository',
          useFactory: () => exceptionRepositoryMock,
        },
      ],
    }).compile();

    updateService = module.get<UpdateService>(UpdateService);
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  it('should be defined', () => {
    expect(updateService).toBeDefined();
  });

  describe('execute', () => {
    it('should update the exception', async () => {
      const updateData: ExceptionUpdateDto = {
        id: 'test_id',
        statusCode: 404,
        message: 'Updated exception message',
        path: 'v1/updated-exception',
        stack: 'Updated exception stack trace',
      };

      await updateService.execute(updateData);

      expect(exceptionRepositoryMock.update).toHaveBeenCalledWith(updateData);
    });
  });
});
