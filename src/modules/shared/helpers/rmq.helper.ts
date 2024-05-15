import { Injectable, Logger, OnModuleInit } from '@nestjs/common';
import { IQueueProvider } from './interfaces/iqueue.provider';
import { Channel, connect, Connection } from 'amqplib';

@Injectable()
export class RmqHelper implements IQueueProvider, OnModuleInit {
  private connection: Connection;
  private channel: Channel;
  protected logger = new Logger();

  async onModuleInit() {
    this.connection = await connect(
      `amqp://${process.env.RMQ_USER}:${process.env.RMQ_PASSWORD}@${process.env.RMQ_URL}`,
    );
    this.channel = await this.connection.createChannel();
  }

  createQueue(
    routeKey: string,
    pattern: string,
    value: any,
    priority = 3,
  ): boolean {
    const content = {
      pattern,
      data: value,
    };
    const buffer = Buffer.from(JSON.stringify(content));
    return this.channel.publish('amq.direct', routeKey, buffer, { priority });
  }
}
