import { CreateService } from '../services/create.service';
import { ExceptionCreateDto } from '../dtos/exception.create.dto';
import { Test, TestingModule } from '@nestjs/testing';

describe('CreateService', () => {
  let createService: CreateService;

  const exceptionRepositoryMock = {
    create: jest.fn(),
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        CreateService,
        {
          provide: 'IExceptionRepository',
          useFactory: () => exceptionRepositoryMock,
        },
      ],
    }).compile();

    createService = module.get<CreateService>(CreateService);
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  it('should be defined', () => {
    expect(createService).toBeDefined();
  });

  describe('execute', () => {
    it('should create an exception with valid data', async () => {
      const exceptionCreateDto: ExceptionCreateDto = {
        statusCode: 500,
        message: 'Test exception message',
        path: 'v1/exception',
        stack: 'Test exception stack trace',
      };
      await createService.execute(exceptionCreateDto);
      expect(exceptionRepositoryMock.create).toHaveBeenCalledWith(
        exceptionCreateDto,
      );
    });
  });
});
