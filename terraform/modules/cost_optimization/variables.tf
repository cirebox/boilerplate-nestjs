# Variáveis para o módulo de otimização de custos
# Este módulo implementa várias estratégias para reduzir custos na infraestrutura

variable "projeto" {
  description = "Nome do projeto para identificação de recursos"
  type        = string
}

variable "ambiente" {
  description = "Ambiente de implantação (dev, staging, prod)"
  type        = string
}

variable "ativar_desligamento_automatico" {
  description = "Ativa o desligamento automático de recursos fora do horário comercial"
  type        = bool
  default     = true
}

variable "recursos_para_desligar" {
  description = "Lista de tipos de recursos para desligar automaticamente fora do horário comercial"
  type        = list(string)
  default     = ["app_servers", "dev_databases", "test_environments"]
}

variable "horario_comercial_inicio" {
  description = "Hora de início do horário comercial (formato 24h, UTC)"
  type        = number
  default     = 8  # 8:00 AM
}

variable "horario_comercial_fim" {
  description = "Hora de término do horário comercial (formato 24h, UTC)"
  type        = number
  default     = 18  # 6:00 PM
}

variable "dias_ativos" {
  description = "Dias da semana em que os recursos devem estar ativos (1 = Segunda-feira, 7 = Domingo)"
  type        = list(number)
  default     = [1, 2, 3, 4, 5]  # Segunda a sexta-feira
}

variable "timezone" {
  description = "Fuso horário para programação de recursos"
  type        = string
  default     = "America/Sao_Paulo"
}

variable "notificacao_email" {
  description = "Endereço de e-mail para notificações de otimização de custos"
  type        = string
}

variable "limiar_utilizacao_cpu" {
  description = "Percentual mínimo de utilização de CPU para alertar sobre subutilização"
  type        = number
  default     = 5
}

variable "limiar_utilizacao_memoria" {
  description = "Percentual mínimo de utilização de memória para alertar sobre subutilização"
  type        = number
  default     = 10
}

variable "periodo_analise" {
  description = "Período de tempo (em dias) para análise de utilização de recursos"
  type        = number
  default     = 7
}

variable "tags_exclusao" {
  description = "Tags de recursos que não devem ser incluídos na otimização de custos"
  type        = list(string)
  default     = ["critical", "always-on", "production-essential"]
}

variable "limite_orcamento" {
  description = "Valor limite do orçamento mensal em dólares que acionará alertas"
  type        = number
  default     = 100
}

variable "percentual_alerta_orcamento" {
  description = "Percentual do limite de orçamento que acionará alertas antecipados"
  type        = list(number)
  default     = [50, 75, 90, 100]
}

variable "webhook_slack" {
  description = "URL do webhook do Slack para envio de alertas de otimização de custos"
  type        = string
  default     = ""
}

variable "intervalo_verificacao" {
  description = "Intervalo em minutos para verificar a utilização de recursos"
  type        = number
  default     = 60
}

variable "permitir_override" {
  description = "Permite que usuários façam override da programação de desligamento para recursos específicos"
  type        = bool
  default     = true
}

variable "tag_override" {
  description = "Nome da tag que, quando presente e definida como 'true', impede o desligamento automático"
  type        = string
  default     = "manter-ativo"
}

variable "manter_snapshots" {
  description = "Número de snapshots a manter antes de desligar um recurso"
  type        = number
  default     = 1
}

variable "tempo_aviso_previo" {
  description = "Tempo em minutos para avisar usuários antes do desligamento automático"
  type        = number
  default     = 30
}

