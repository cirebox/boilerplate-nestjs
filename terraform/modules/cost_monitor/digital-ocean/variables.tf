variable "environment" {
  description = "Ambiente de deploy (dev, staging, prod)"
  type        = string
}

variable "project_name" {
  description = "Nome do projeto"
  type        = string
}

variable "alert_emails" {
  description = "Lista de emails para receber alertas de custos"
  type        = list(string)
}

variable "slack_channel" {
  description = "Canal do Slack para alertas (opcional)"
  type        = string
  default     = ""
}

variable "slack_webhook_url" {
  description = "URL do webhook do Slack para alertas (opcional)"
  type        = string
  default     = ""
  sensitive   = true
}

variable "budget_threshold" {
  description = "Limite de gastos diários que acionará um alerta ($)"
  type        = number
  default     = 10
}

variable "monthly_budget_limit" {
  description = "Limite de gastos mensais que acionará um alerta ($)"
  type        = number
  default     = 100
}

variable "enable_waste_detection" {
  description = "Ativar alertas para detecção de recursos subutilizados"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags adicionais para aplicar nos recursos"
  type        = list(string)
  default     = []
}