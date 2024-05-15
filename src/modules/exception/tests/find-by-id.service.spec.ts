import { Test, TestingModule } from '@nestjs/testing';
import { FindByIdService } from '../services/find-by-id.service';

describe('FindByIdService', () => {
  let findByIdService: FindByIdService;
  const exceptionRepositoryMock = {
    findById: jest.fn(),
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        FindByIdService,
        {
          provide: 'IExceptionRepository',
          useFactory: () => exceptionRepositoryMock,
        },
      ],
    }).compile();

    findByIdService = module.get<FindByIdService>(FindByIdService);
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  it('should be defined', () => {
    expect(findByIdService).toBeDefined();
  });

  describe('execute', () => {
    it('should find exception by id', async () => {
      const id = 'test_id';
      const mockException = {};
      exceptionRepositoryMock.findById.mockResolvedValue(mockException);

      await findByIdService.execute(id);

      expect(exceptionRepositoryMock.findById).toHaveBeenCalledWith(id);
    });
  });
});
