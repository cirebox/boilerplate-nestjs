import { DynamicModule, Injectable, Module } from '@nestjs/common';
import { IQueueProvider } from './interfaces/iqueue.provider';
import { RabbitMQProvider } from './rabbit-mq.provider';
import { KafkaProvider } from './kafka-mq.provider';
import { BullMQProvider } from './bull-mq.provider';

/**
 * Fábrica de MQ Provider baseada em configuração
 */
@Injectable()
export class MQProviderFactory {
  static create(): IQueueProvider {
    const mqType = process.env.MQ_TYPE?.toLowerCase() || 'rabbitmq';

    switch (mqType) {
      case 'rabbitmq':
        return new RabbitMQProvider();
      case 'kafka':
        return new KafkaProvider();
      case 'bullmq':
        return new BullMQProvider();
      default:
        throw new Error(`Unsupported MQ type: ${mqType}`);
    }
  }
}

@Module({})
export class MessageQueueModule {
  static forRoot(mqType?: string): DynamicModule {
    // Override environment MQ_TYPE if provided
    if (mqType) {
      process.env.MQ_TYPE = mqType;
    }

    const mqProviderFactory = {
      provide: 'IQueueProvider',
      useFactory: () => MQProviderFactory.create(),
    };

    return {
      module: MessageQueueModule,
      providers: [mqProviderFactory],
      exports: [mqProviderFactory],
      global: true,
    };
  }

  static forFeature(): DynamicModule {
    return {
      module: MessageQueueModule,
      providers: [],
      exports: [],
    };
  }
}
