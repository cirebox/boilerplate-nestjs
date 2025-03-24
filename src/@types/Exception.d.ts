declare namespace ApiTypes {
  interface Exception {
    /**
     * ID único da exceção, gerado automaticamente em formato UUID.
     */
    id?: string;

    /**
     * Representa o código de status HTTP da exceção.
     * Exemplo: 404 para "Não Encontrado", 500 para "Erro Interno do Servidor".
     */
    statusCode: number;

    /**
     * Mensagem descritiva do erro ou exceção.
     * Indica a natureza do problema encontrado.
     */
    message: string;

    /**
     * Caminho ou rota onde o erro ocorreu, se aplicável.
     * Este campo é opcional e pode ajudar a identificar o local exato no código que causou o erro.
     */
    path?: string;

    /**
     * Stack trace do erro, útil para depuração.
     * Este campo é opcional e pode fornecer informações detalhadas sobre o fluxo de execução.
     */
    stack?: string;

    /**
     * Data e hora em que o erro foi registrado.
     * Valor padrão é a data e hora atual.
     */
    createdAt?: string | Date;
  }

  interface ExceptionListResponse {
    data: Exception[];
    total: number;
    page: number;
    limit: number;
    totalPages: number;
  }
}
