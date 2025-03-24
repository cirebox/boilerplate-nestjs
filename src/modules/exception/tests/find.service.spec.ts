import { Test, TestingModule } from '@nestjs/testing';
import { FindService } from '../services/find.service';

describe('FindService', () => {
  let findService: FindService;

  const exceptionRepositoryMock = {
    find: jest.fn(),
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        FindService,
        {
          provide: 'IExceptionRepository',
          useFactory: () => exceptionRepositoryMock,
        },
      ],
    }).compile();

    findService = module.get<FindService>(FindService);
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  it('should be defined', () => {
    expect(findService).toBeDefined();
  });

  describe('execute', () => {
    it('should find all exceptions', async () => {
      const mockExceptions: any = [];
      exceptionRepositoryMock.find.mockResolvedValue(mockExceptions);

      await findService.execute();

      expect(exceptionRepositoryMock.find).toHaveBeenCalled();
    });
  });
});
