variable "environment" {
  description = "Ambiente de deploy (dev, staging, prod)"
  type        = string
}

variable "project_name" {
  description = "Nome do projeto"
  type        = string
}

variable "project_id" {
  description = "ID do projeto GCP"
  type        = string
}

variable "billing_account_id" {
  description = "ID da conta de faturamento do GCP"
  type        = string
}

variable "budget_amount" {
  description = "Valor máximo do orçamento mensal"
  type        = number
}

variable "budget_currency" {
  description = "Moeda do orçamento (USD, BRL, etc)"
  type        = string
  default     = "USD"
}

variable "alert_threshold_percent" {
  description = "Porcentagem do orçamento para acionar alertas"
  type        = number
  default     = 80
}

variable "notification_channel_ids" {
  description = "Lista de IDs dos canais de notificação do Cloud Monitoring para enviar alertas"
  type        = list(string)
  default     = []
}

variable "alert_emails" {
  description = "Lista de e-mails para receber alertas de orçamento"
  type        = list(string)
}

variable "tags" {
  description = "Tags a serem aplicadas a todos os recursos"
  type        = map(string)
  default     = {}
}