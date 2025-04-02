import { Test, TestingModule } from '@nestjs/testing';
import { Logger } from '@nestjs/common';
import { YourService } from '../services/mq.service';
import { IQueueProvider } from 'src/modules/shared/providers/mq/interfaces/iqueue.provider';

describe('YourService', () => {
  let service: YourService;
  let mockMqProvider: jest.Mocked<IQueueProvider>;

  beforeEach(async () => {
    // Mock para o IQueueProvider
    mockMqProvider = {
      publishMessage: jest.fn(),
      subscribeToMessages: jest.fn(),
      unsubscribe: jest.fn(),
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        YourService,
        {
          provide: 'IQueueProvider',
          useValue: mockMqProvider,
        },
      ],
    }).compile();

    service = module.get<YourService>(YourService);

    // Sobrescrever o logger para evitar logs durante os testes
    jest.spyOn(Logger.prototype, 'log').mockImplementation(() => {});
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  describe('sendMessage', () => {
    it('deve publicar uma mensagem usando o mqProvider', async () => {
      // Arrange
      const testData = { id: 1, name: 'test' };
      mockMqProvider.publishMessage.mockResolvedValue(true);

      // Act
      await service.sendMessage(testData);

      // Assert
      expect(mockMqProvider.publishMessage).toHaveBeenCalledWith(
        'your-queue-or-topic',
        'data.created',
        testData,
        { priority: 5 },
      );
      expect(mockMqProvider.publishMessage).toHaveBeenCalledTimes(1);
    });

    it('deve lidar com falhas ao publicar mensagem', async () => {
      // Arrange
      const testData = { id: 1, name: 'test' };
      mockMqProvider.publishMessage.mockRejectedValue(
        new Error('Falha ao publicar'),
      );

      // Act & Assert
      await expect(service.sendMessage(testData)).rejects.toThrow(
        'Falha ao publicar',
      );
      expect(mockMqProvider.publishMessage).toHaveBeenCalledTimes(1);
    });
  });

  describe('setupConsumer', () => {
    it('deve configurar um consumidor para a fila', async () => {
      // Arrange
      const mockSubscriptionId = 'mock-subscription-id';
      mockMqProvider.subscribeToMessages.mockResolvedValue(mockSubscriptionId);

      // Spy no logger
      const logSpy = jest.spyOn(service['logger'], 'log');

      // Act
      await service.setupConsumer();

      // Assert
      expect(mockMqProvider.subscribeToMessages).toHaveBeenCalledWith(
        'your-queue-or-topic',
        expect.any(Function),
      );
      expect(mockMqProvider.subscribeToMessages).toHaveBeenCalledTimes(1);
      expect(logSpy).toHaveBeenCalledWith(
        `Unsubscribed worker (ID: ${mockSubscriptionId})`,
      );
    });

    it('deve lidar com erros ao configurar o consumidor', async () => {
      // Arrange
      mockMqProvider.subscribeToMessages.mockRejectedValue(
        new Error('Falha na configuração'),
      );

      // Act & Assert
      await expect(service.setupConsumer()).rejects.toThrow(
        'Falha na configuração',
      );
      expect(mockMqProvider.subscribeToMessages).toHaveBeenCalledTimes(1);
    });

    it('deve processar mensagens recebidas corretamente', async () => {
      // Arrange
      let messageHandler: (message: any) => Promise<void>;
      mockMqProvider.subscribeToMessages.mockImplementation(
        async (_source, handler) => {
          messageHandler = handler;
          return 'subscription-id';
        },
      );

      // Spy no console.log
      const consoleSpy = jest.spyOn(console, 'log').mockImplementation();

      // Act
      await service.setupConsumer();

      // Simular recebimento de mensagem
      const testMessage = { data: 'test message' };
      await messageHandler!(testMessage);

      // Assert
      expect(consoleSpy).toHaveBeenCalledWith('Received message:', testMessage);
    });
  });
});
