/**
 * Variáveis para o módulo de Monitoramento DigitalOcean
 *
 * Este arquivo define todas as variáveis necessárias para o
 * módulo de monitoramento de recursos no DigitalOcean
 */

variable "environment" {
  description = "Ambiente de deploy (dev, staging, prod)"
  type        = string
}

variable "project_name" {
  description = "Nome do projeto"
  type        = string
}

variable "cpu_threshold" {
  description = "Limite percentual de CPU para acionar alertas"
  type        = number
  default     = 80
}

variable "memory_threshold" {
  description = "Limite percentual de memória para acionar alertas"
  type        = number
  default     = 80
}

variable "disk_threshold" {
  description = "Limite percentual de utilização de disco para acionar alertas"
  type        = number
  default     = 85
}

variable "service_name" {
  description = "Nome do serviço Kubernetes a ser monitorado"
  type        = string
}

variable "cluster_name" {
  description = "Nome do cluster Kubernetes a ser monitorado"
  type        = string
}

variable "service_endpoint" {
  description = "Endpoint do serviço para monitoramento de disponibilidade"
  type        = string
  default     = "https://api.example.com/health"
}

variable "notification_emails" {
  description = "Lista de emails para envio de notificações"
  type        = list(string)
  default     = []
}

variable "slack_channel" {
  description = "Canal do Slack para notificações"
  type        = string
  default     = ""
}

variable "slack_webhook_url" {
  description = "URL do webhook do Slack para notificações"
  type        = string
  default     = ""
}

variable "tags" {
  description = "Tags adicionais para os recursos"
  type        = map(string)
  default     = {}
}