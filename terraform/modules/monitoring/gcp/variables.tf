/**
 * Variáveis para o módulo de Monitoramento GCP
 *
 * Este arquivo define todas as variáveis necessárias para o
 * módulo de monitoramento de recursos no Google Cloud Platform
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

variable "service_name" {
  description = "Nome do serviço Kubernetes a ser monitorado"
  type        = string
}

variable "cluster_name" {
  description = "Nome do cluster Kubernetes a ser monitorado"
  type        = string
}

variable "namespace" {
  description = "Namespace Kubernetes onde o serviço está implantado"
  type        = string
  default     = "default"
}

variable "notification_emails" {
  description = "Lista de emails para envio de notificações"
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Tags adicionais para os recursos"
  type        = map(string)
  default     = {}
}