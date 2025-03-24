import { Injectable } from '@nestjs/common';
import { BaseMQProvider } from './base-mq.provider';

/**
 * Implementação para BullMQ
 */
@Injectable()
export class BullMQProvider extends BaseMQProvider {
  private queues: Map<string, any> = new Map();
  private workers: Map<string, any> = new Map();
  private redisOptions: any;

  protected async connect(): Promise<boolean> {
    try {
      this.redisOptions = {
        host: process.env.REDIS_HOST || 'localhost',
        port: parseInt(process.env.REDIS_PORT || '6379'),
        password: process.env.REDIS_PASSWORD,
        db: parseInt(process.env.REDIS_DB || '0'),
      };

      this.logger.debug(
        `Connecting to Redis for BullMQ: ${this.redisOptions.host}:${this.redisOptions.port}`,
      );

      // Não precisa estabelecer conexão explícita com BullMQ
      // As conexões são feitas quando queues são criadas

      this.isConnected = true;
      this.reconnectAttempts = 0;
      this.logger.log('BullMQ setup complete');

      return true;
    } catch (error) {
      this.logger.error('Failed to setup BullMQ', error.stack);
      this.isConnected = false;
      this.attemptReconnect();
      return false;
    }
  }

  protected async disconnect(): Promise<void> {
    try {
      // Fechar todos os workers
      for (const [key, worker] of this.workers.entries()) {
        await worker.close();
        this.logger.debug(`BullMQ worker closed for ${key}`);
      }

      // Limpar maps
      this.workers.clear();
      this.queues.clear();

      this.isConnected = false;
      this.logger.log('BullMQ connection closed');
    } catch (error) {
      this.logger.error('Error closing BullMQ connection', error.stack);
    }
  }

  async publishMessage(
    destination: string,
    messageType: string,
    payload: any,
    options: { delay?: number; priority?: number } = {},
  ): Promise<boolean> {
    if (!this.isConnected) {
      this.logger.warn('Cannot publish message: BullMQ not set up');
      await this.connect();
      if (!this.isConnected) {
        return false;
      }
    }

    try {
      // Importação dinâmica para não depender da biblioteca se não for usar BullMQ
      const { Queue } = await import('bullmq');

      // Obter ou criar a fila
      let queue = this.queues.get(destination);
      if (!queue) {
        queue = new Queue(destination, { connection: this.redisOptions });
        this.queues.set(destination, queue);
      }

      // Adicionar job à fila
      await queue.add(
        messageType,
        {
          type: messageType,
          payload,
          timestamp: Date.now(),
        },
        {
          priority: options.priority,
          delay: options.delay,
          removeOnComplete: true,
          removeOnFail: 1000,
        },
      );

      this.logger.debug(`Message published to queue ${destination}`);
      return true;
    } catch (error) {
      this.logger.error(
        `Error publishing message to ${destination}`,
        error.stack,
      );
      return false;
    }
  }

  async subscribeToMessages(
    source: string,
    handler: (message: any) => Promise<void>,
    options: { concurrency?: number } = {},
  ): Promise<string> {
    if (!this.isConnected) {
      this.logger.warn('Cannot subscribe: BullMQ not set up');
      await this.connect();
      if (!this.isConnected) {
        throw new Error('Failed to set up BullMQ');
      }
    }

    try {
      // Importação dinâmica
      const { Worker } = await import('bullmq');

      // Generate subscription ID
      const subscriptionId = `sub_${Date.now()}_${Math.random().toString(36).substring(2, 9)}`;

      // Create worker
      const worker = new Worker(
        source,
        async (job) => {
          try {
            await handler(job.data);
          } catch (error) {
            this.logger.error(
              `Error processing job from ${source}`,
              error.stack,
            );
            throw error; // Rethrow to mark job as failed
          }
        },
        {
          connection: this.redisOptions,
          concurrency: options.concurrency || 1,
        },
      );

      // Setup event handlers
      worker.on('completed', (job) => {
        this.logger.debug(`Job ${job.id} completed successfully`);
      });

      worker.on('failed', (job, error) => {
        this.logger.error(`Job ${job?.id} failed: ${error.message}`);
      });

      // Store worker
      this.workers.set(subscriptionId, worker);

      this.logger.log(
        `Started worker for queue: ${source} (ID: ${subscriptionId})`,
      );
      return subscriptionId;
    } catch (error) {
      this.logger.error(`Error setting up worker for ${source}`, error.stack);
      throw error;
    }
  }

  async unsubscribe(subscriptionId: string): Promise<boolean> {
    if (!this.isConnected) {
      this.logger.warn('Cannot unsubscribe: BullMQ not set up');
      return false;
    }

    const worker = this.workers.get(subscriptionId);
    if (!worker) {
      this.logger.warn(`Subscription ${subscriptionId} not found`);
      return false;
    }

    try {
      await worker.close();
      this.workers.delete(subscriptionId);
      this.logger.log(`Unsubscribed worker (ID: ${subscriptionId})`);
      return true;
    } catch (error) {
      this.logger.error(`Error unsubscribing worker`, error.stack);
      return false;
    }
  }
}
