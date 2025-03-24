import { Injectable } from '@nestjs/common';
import { BaseMQProvider } from './base-mq.provider';

/**
 * Implementação para Kafka
 */
@Injectable()
export class KafkaProvider extends BaseMQProvider {
  private producer?: any;
  private consumer?: any;
  private kafka?: any;
  private admin?: any;
  private subscriptions: Map<string, { groupId: string; topic: string }> =
    new Map();

  protected async connect(): Promise<boolean> {
    try {
      // Importação dinâmica para não depender da biblioteca se não for usar Kafka
      const { Kafka } = await import('kafkajs');

      const brokers = (process.env.MQ_BROKERS || 'localhost:9092').split(',');
      const clientId = process.env.MQ_CLIENT_ID || 'nestjs-app';

      this.logger.debug(`Connecting to Kafka: ${brokers.join(', ')}`);

      this.kafka = new Kafka({
        clientId,
        brokers,
        ssl: process.env.MQ_SSL === 'true',
        ...(process.env.MQ_USERNAME && {
          sasl: {
            mechanism: 'plain',
            username: process.env.MQ_USERNAME,
            password: process.env.MQ_PASSWORD || '',
          },
        }),
      });

      this.admin = this.kafka.admin();
      await this.admin.connect();

      this.producer = this.kafka.producer();
      await this.producer.connect();

      this.consumer = this.kafka.consumer({
        groupId: `${clientId}-${Date.now()}`,
        allowAutoTopicCreation: true,
      });
      await this.consumer.connect();

      this.isConnected = true;
      this.reconnectAttempts = 0;
      this.logger.log('Successfully connected to Kafka');

      return true;
    } catch (error) {
      this.logger.error('Failed to connect to Kafka', error.stack);
      this.isConnected = false;
      this.attemptReconnect();
      return false;
    }
  }

  protected async disconnect(): Promise<void> {
    try {
      if (this.producer) {
        await this.producer.disconnect();
        this.logger.debug('Kafka producer disconnected');
      }

      if (this.consumer) {
        await this.consumer.disconnect();
        this.logger.debug('Kafka consumer disconnected');
      }

      if (this.admin) {
        await this.admin.disconnect();
        this.logger.debug('Kafka admin disconnected');
      }

      this.isConnected = false;
    } catch (error) {
      this.logger.error('Error disconnecting from Kafka', error.stack);
    }
  }

  async publishMessage(
    destination: string,
    messageType: string,
    payload: any,
    options: { partition?: number } = {},
  ): Promise<boolean> {
    if (!this.isConnected || !this.producer) {
      this.logger.warn('Cannot publish message: Not connected to Kafka');
      await this.connect();
      if (!this.isConnected || !this.producer) {
        return false;
      }
    }

    try {
      // Ensure topic exists
      await this.admin?.createTopics({
        topics: [{ topic: destination }],
        waitForLeaders: true,
      });

      // Create message
      const message = {
        key: messageType,
        value: JSON.stringify({
          type: messageType,
          payload,
          timestamp: Date.now(),
        }),
      };

      // Send message
      await this.producer.send({
        topic: destination,
        messages: [message],
        ...(options.partition !== undefined && {
          partition: options.partition,
        }),
      });

      this.logger.debug(`Message published to topic ${destination}`);
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
    options: { groupId?: string; fromBeginning?: boolean } = {},
  ): Promise<string> {
    if (!this.isConnected || !this.consumer) {
      this.logger.warn('Cannot subscribe: Not connected to Kafka');
      await this.connect();
      if (!this.isConnected || !this.consumer) {
        throw new Error('Failed to connect to Kafka');
      }
    }

    try {
      // Generate subscription ID and group ID
      const subscriptionId = `sub_${Date.now()}_${Math.random().toString(36).substring(2, 9)}`;
      const groupId = options.groupId || `group-${subscriptionId}`;

      // Subscribe to topic
      await this.consumer.subscribe({
        topic: source,
        fromBeginning: options.fromBeginning ?? false,
      });

      // Start consuming
      await this.consumer.run({
        eachMessage: async ({ topic, message }: any) => {
          try {
            if (!message || !message.value) {
              this.logger.warn(`Received null message from ${topic}`);
              return;
            }

            const content = JSON.parse(message.value.toString());
            await handler(content);
          } catch (error) {
            this.logger.error(
              `Error processing message from ${topic}`,
              error.stack,
            );
          }
        },
      });

      // Store subscription details
      this.subscriptions.set(subscriptionId, { topic: source, groupId });

      this.logger.log(
        `Started consuming from topic: ${source} (ID: ${subscriptionId})`,
      );
      return subscriptionId;
    } catch (error) {
      this.logger.error(`Error setting up consumer for ${source}`, error.stack);
      throw error;
    }
  }

  async unsubscribe(subscriptionId: string): Promise<boolean> {
    if (!this.isConnected || !this.consumer) {
      this.logger.warn('Cannot unsubscribe: Not connected to Kafka');
      return false;
    }

    const subscription = this.subscriptions.get(subscriptionId);
    if (!subscription) {
      this.logger.warn(`Subscription ${subscriptionId} not found`);
      return false;
    }

    try {
      await this.consumer.stop();
      this.subscriptions.delete(subscriptionId);
      this.logger.log(
        `Unsubscribed from ${subscription.topic} (ID: ${subscriptionId})`,
      );
      return true;
    } catch (error) {
      this.logger.error(
        `Error unsubscribing from ${subscription.topic}`,
        error.stack,
      );
      return false;
    }
  }
}
