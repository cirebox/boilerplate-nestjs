import { Injectable } from '@nestjs/common';
import { BaseMQProvider } from './base-mq.provider';

/**
 * Implementação para RabbitMQ
 */
@Injectable()
export class RabbitMQProvider extends BaseMQProvider {
  private connection?: any; // amqplib.Connection
  private channel?: any; // amqplib.Channel
  private subscriptions: Map<string, { queue: string; consumerTag: string }> =
    new Map();

  protected async connect(): Promise<boolean> {
    try {
      // Importação dinâmica para não depender da biblioteca se não for usar RabbitMQ
      const amqplib = await import('amqplib');

      const connectionString = `amqp://${process.env.MQ_USER || 'guest'}:${process.env.MQ_PASSWORD || 'guest'}@${process.env.MQ_HOST || 'localhost'}:${process.env.MQ_PORT || '5672'}`;
      this.logger.debug(
        `Connecting to RabbitMQ: ${process.env.MQ_HOST || 'localhost'}:${process.env.MQ_PORT || '5672'}`,
      );

      this.connection = await amqplib.connect(connectionString);

      this.connection.on('error', (err: Error) => {
        this.logger.error(`RabbitMQ connection error: ${err.message}`);
        this.isConnected = false;
        this.attemptReconnect();
      });

      this.connection.on('close', () => {
        this.logger.warn('RabbitMQ connection closed');
        this.isConnected = false;
        this.attemptReconnect();
      });

      this.channel = await this.connection.createChannel();

      this.channel.on('error', (err: Error) => {
        this.logger.error(`RabbitMQ channel error: ${err.message}`);
        this.isConnected = false;
      });

      this.channel.on('close', () => {
        this.logger.warn('RabbitMQ channel closed');
        this.isConnected = false;
      });

      this.reconnectAttempts = 0;
      this.isConnected = true;
      this.logger.log('Successfully connected to RabbitMQ');

      return true;
    } catch (error) {
      this.logger.error('Failed to connect to RabbitMQ', error.stack);
      this.isConnected = false;
      this.attemptReconnect();
      return false;
    }
  }

  protected async disconnect(): Promise<void> {
    try {
      if (this.channel) {
        await this.channel.close();
        this.logger.debug('RabbitMQ channel closed');
      }

      if (this.connection) {
        await this.connection.close();
        this.logger.debug('RabbitMQ connection closed');
      }

      this.isConnected = false;
    } catch (error) {
      this.logger.error('Error closing RabbitMQ connection', error.stack);
    }
  }

  async publishMessage(
    destination: string,
    messageType: string,
    payload: any,
    options: { exchange?: string; priority?: number } = {},
  ): Promise<boolean> {
    if (!this.isConnected || !this.channel) {
      this.logger.warn('Cannot publish message: Not connected to RabbitMQ');
      await this.connect();
      if (!this.isConnected || !this.channel) {
        return false;
      }
    }

    try {
      const exchange = options.exchange || 'amq.direct';
      const content = {
        type: messageType,
        payload,
        timestamp: Date.now(),
      };

      const buffer = Buffer.from(JSON.stringify(content));

      // Ensure exchange exists
      await this.channel.assertExchange(exchange, 'direct', { durable: true });

      // Ensure queue exists
      await this.channel.assertQueue(destination, { durable: true });

      // Bind queue to exchange
      await this.channel.bindQueue(destination, exchange, destination);

      // Publish message
      const result = this.channel.publish(exchange, destination, buffer, {
        persistent: true,
        priority: options.priority ?? 0,
        contentType: 'application/json',
      });

      if (result) {
        this.logger.debug(`Message published to ${destination}`);
      } else {
        this.logger.warn(`Failed to publish message to ${destination}`);
      }

      return result;
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
    options: { prefetch?: number } = {},
  ): Promise<string> {
    if (!this.isConnected || !this.channel) {
      this.logger.warn('Cannot subscribe: Not connected to RabbitMQ');
      await this.connect();
      if (!this.isConnected || !this.channel) {
        throw new Error('Failed to connect to RabbitMQ');
      }
    }

    try {
      // Set prefetch if provided
      if (options.prefetch) {
        await this.channel.prefetch(options.prefetch);
      }

      // Ensure queue exists
      await this.channel.assertQueue(source, { durable: true });

      // Generate subscription ID
      const subscriptionId = `sub_${Date.now()}_${Math.random().toString(36).substring(2, 9)}`;

      // Start consuming
      const { consumerTag } = await this.channel.consume(
        source,
        async (msg: any) => {
          if (!msg) {
            this.logger.warn(`Received null message from ${source}`);
            return;
          }

          try {
            const content = JSON.parse(msg.content.toString());
            await handler(content);
            this.channel?.ack(msg);
          } catch (error) {
            this.logger.error(
              `Error processing message from ${source}`,
              error.stack,
            );
            // Nack without requeue to prevent message loops
            this.channel?.nack(msg, false, false);
          }
        },
      );

      // Store subscription details
      this.subscriptions.set(subscriptionId, { queue: source, consumerTag });

      this.logger.log(
        `Started consuming from queue: ${source} (ID: ${subscriptionId})`,
      );
      return subscriptionId;
    } catch (error) {
      this.logger.error(`Error setting up consumer for ${source}`, error.stack);
      throw error;
    }
  }

  async unsubscribe(subscriptionId: string): Promise<boolean> {
    if (!this.isConnected || !this.channel) {
      this.logger.warn('Cannot unsubscribe: Not connected to RabbitMQ');
      return false;
    }

    const subscription = this.subscriptions.get(subscriptionId);
    if (!subscription) {
      this.logger.warn(`Subscription ${subscriptionId} not found`);
      return false;
    }

    try {
      await this.channel.cancel(subscription.consumerTag);
      this.subscriptions.delete(subscriptionId);
      this.logger.log(
        `Unsubscribed from ${subscription.queue} (ID: ${subscriptionId})`,
      );
      return true;
    } catch (error) {
      this.logger.error(
        `Error unsubscribing from ${subscription.queue}`,
        error.stack,
      );
      return false;
    }
  }
}
