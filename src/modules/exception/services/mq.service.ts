import { Injectable, Inject, Logger } from '@nestjs/common';
import { IQueueProvider } from 'src/modules/shared/providers/mq/interfaces/iqueue.provider';

@Injectable()
export class YourService {
  protected readonly logger = new Logger(this.constructor.name);
  constructor(
    @Inject('IQueueProvider')
    private readonly mqProvider: IQueueProvider,
  ) {}

  async sendMessage(data: any): Promise<void> {
    await this.mqProvider.publishMessage(
      'your-queue-or-topic',
      'data.created',
      data,
      { priority: 5 },
    );
  }

  async setupConsumer(): Promise<void> {
    const subscriptionId = await this.mqProvider.subscribeToMessages(
      'your-queue-or-topic',
      async (message) => {
        console.log('Received message:', message);
        // Process message...
      },
    );
    this.logger.log(`Unsubscribed worker (ID: ${subscriptionId})`);
    // Store subscriptionId if you need to unsubscribe later
  }
}
