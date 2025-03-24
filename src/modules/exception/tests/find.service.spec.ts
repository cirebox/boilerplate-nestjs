import { Test, TestingModule } from '@nestjs/testing';
import { FindService } from '../services/find.service';
import { ExceptionFilterDto } from '../dtos/exception.filter.dto';

describe('FindService', () => {
  let findService: FindService;

  const exceptionRepositoryMock = {
    findWithPagination: jest.fn(),
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
    it('should find exceptions with pagination when filter is provided', async () => {
      const filter: ExceptionFilterDto = {
        page: 2,
        limit: 5,
        getSkip: () => (2 - 1) * 5,
        getOrderBy: () => ({ key: 'id' }),
      };
      const mockExceptions = [
        { id: '1', message: 'test' },
        { id: '2', message: 'test2' },
      ];
      const mockTotal = 10;

      exceptionRepositoryMock.findWithPagination.mockResolvedValue([
        mockExceptions,
        mockTotal,
      ]);

      const result = await findService.execute(filter);

      expect(exceptionRepositoryMock.findWithPagination).toHaveBeenCalledWith(
        filter,
        5, // skip (page - 1) * limit
        5, // limit
      );

      expect(result).toEqual({
        data: mockExceptions,
        total: mockTotal,
        page: 2,
        limit: 5,
        totalPages: 2, // Math.ceil(10/5)
      });
    });

    it('should use default pagination values when filter is not provided', async () => {
      const mockExceptions = [{ id: '1', message: 'test' }];
      const mockTotal = 1;

      exceptionRepositoryMock.findWithPagination.mockResolvedValue([
        mockExceptions,
        mockTotal,
      ]);

      const result = await findService.execute();

      expect(exceptionRepositoryMock.findWithPagination).toHaveBeenCalledWith(
        undefined,
        0, // skip (1-1) * 10
        10, // default limit
      );

      expect(result).toEqual({
        data: mockExceptions,
        total: mockTotal,
        page: 1,
        limit: 10,
        totalPages: 1,
      });
    });
  });
});
