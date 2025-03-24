/**
 * Interface base para provedores de mensageria
 */
export interface IQueueProvider {
  /**
   * Publica uma mensagem em uma fila/tópico
   * @param destination Nome da fila/tópico ou chave de roteamento
   * @param messageType Tipo ou padrão da mensagem
   * @param payload Dados da mensagem
   * @param options Opções adicionais específicas do provedor
   * @returns Promise<boolean> Sucesso da operação
   */
  publishMessage(
    destination: string,
    messageType: string,
    payload: any,
    options?: Record<string, any>,
  ): Promise<boolean>;

  /**
   * Configura um consumidor para uma fila/tópico
   * @param source Nome da fila/tópico ou padrão de inscrição
   * @param handler Função para processar mensagens recebidas
   * @param options Opções adicionais específicas do provedor
   * @returns Promise<string> ID ou identificador da inscrição
   */
  subscribeToMessages(
    source: string,
    handler: (message: any) => Promise<void>,
    options?: Record<string, any>,
  ): Promise<string>;

  /**
   * Cancela a inscrição de um consumidor
   * @param subscriptionId ID da inscrição retornado por subscribeToMessages
   * @returns Promise<boolean> Sucesso da operação
   */
  unsubscribe(subscriptionId: string): Promise<boolean>;
}
