/**
 * Variáveis para o módulo de Monitoramento AWS
 *
 * Este arquivo define todas as variáveis necessárias para o
 * módulo de monitoramento de recursos na AWS
 */

variable "environment" {
  description = "Ambiente de deploy (dev, staging, prod)"
  type        = string
}

variable "project_name" {
  description = "Nome do projeto"
  type        = string
}

variable "webhook_url" {
  description = "URL do webhook para notificações (Slack, Teams, etc)"
  type        = string
  default     = ""
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

variable "service_name" {
  description = "Nome do serviço ECS a ser monitorado"
  type        = string
}

variable "cluster_name" {
  description = "Nome do cluster ECS ou EKS a ser monitorado"
  type        = string
}

variable "kubernetes_service" {
  description = "Define se o serviço é Kubernetes (EKS) em vez de ECS"
  type        = bool
  default     = false
}

variable "namespace" {
  description = "Namespace do Kubernetes a ser monitorado (somente quando kubernetes_service = true)"
  type        = string
  default     = "default"
}

variable "notification_emails" {
  description = "Lista de emails para envio de notificações"
  type        = list(string)
  default     = []
}

variable "evaluation_periods" {
  description = "Número de períodos para avaliação dos alertas"
  type        = number
  default     = 2
}

variable "period" {
  description = "Período de avaliação em segundos"
  type        = number
  default     = 300
}

variable "tags" {
  description = "Tags adicionais para os recursos"
  type        = map(string)
  default     = {}
}