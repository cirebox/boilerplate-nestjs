import { Test, TestingModule } from '@nestjs/testing';
import { DeleteService } from '../services/delete.service';

describe('DeleteService', () => {
  let deleteService: DeleteService;
  const exceptionRepositoryMock = {
    delete: jest.fn(),
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        DeleteService,
        {
          provide: 'IExceptionRepository',
          useFactory: () => exceptionRepositoryMock,
        },
      ],
    }).compile();

    deleteService = module.get<DeleteService>(DeleteService);
  });

  it('should be defined', () => {
    expect(deleteService).toBeDefined();
  });

  describe('execute', () => {
    it('should delete the exception by ID', async () => {
      const exceptionId = 'test_exception_id';
      await deleteService.execute(exceptionId);
      expect(exceptionRepositoryMock.delete).toHaveBeenCalledWith(exceptionId);
    });
  });
});
