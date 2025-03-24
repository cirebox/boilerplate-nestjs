import {
  Injectable,
  Logger,
  OnModuleInit,
  OnModuleDestroy,
} from '@nestjs/common';
import { IQueueProvider } from './interfaces/iqueue.provider';

/**
 * Classe abstrata base para implementações específicas de provedores MQ
 */
@Injectable()
export abstract class BaseMQProvider
  implements IQueueProvider, OnModuleInit, OnModuleDestroy
{
  protected readonly logger = new Logger(this.constructor.name);
  protected isConnected = false;
  protected reconnectAttempts = 0;
  protected readonly maxReconnectAttempts = 5;
  protected readonly reconnectInterval = 5000; // 5 segundos

  async onModuleInit() {
    await this.connect();
  }

  async onModuleDestroy() {
    await this.disconnect();
  }

  /**
   * Método abstrato para estabelecer conexão com o broker
   * Deve ser implementado por classes concretas
   */
  protected abstract connect(): Promise<boolean>;

  /**
   * Método abstrato para desconectar do broker
   * Deve ser implementado por classes concretas
   */
  protected abstract disconnect(): Promise<void>;

  /**
   * Implementação padrão de tentativa de reconexão
   */
  protected async attemptReconnect(): Promise<void> {
    if (this.reconnectAttempts >= this.maxReconnectAttempts) {
      this.logger.error(
        `Failed to reconnect after ${this.maxReconnectAttempts} attempts`,
      );
      return;
    }

    this.reconnectAttempts++;
    this.logger.log(
      `Attempting to reconnect (${this.reconnectAttempts}/${this.maxReconnectAttempts})...`,
    );

    setTimeout(async () => {
      await this.connect();
    }, this.reconnectInterval);
  }

  /**
   * Método abstrato para publicar mensagens
   * Deve ser implementado por classes concretas
   */
  abstract publishMessage(
    destination: string,
    messageType: string,
    payload: any,
    options?: Record<string, any>,
  ): Promise<boolean>;

  /**
   * Método abstrato para subscrever a mensagens
   * Deve ser implementado por classes concretas
   */
  abstract subscribeToMessages(
    source: string,
    handler: (message: any) => Promise<void>,
    options?: Record<string, any>,
  ): Promise<string>;

  /**
   * Método abstrato para cancelar subscrição
   * Deve ser implementado por classes concretas
   */
  abstract unsubscribe(subscriptionId: string): Promise<boolean>;
}
