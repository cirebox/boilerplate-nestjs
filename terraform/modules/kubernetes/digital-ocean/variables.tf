variable "environment" {
  description = "Ambiente de deploy (dev, staging, prod)"
  type        = string
}

variable "project_name" {
  description = "Nome do projeto"
  type        = string
}

# Adicionando a variável enabled para controlar a criação de recursos
variable "enabled" {
  description = "Flag para ativar ou desativar a criação de recursos deste módulo"
  type        = bool
  default     = true
}

variable "cluster_name" {
  description = "Nome do cluster Kubernetes (opcionalmente fornecido externamente)"
  type        = string
  default     = null
}

variable "region" {
  description = "Região do Digital Ocean"
  type        = string
}

variable "vpc_id" {
  description = "ID da VPC onde o cluster será implantado"
  type        = string
}

variable "kubernetes_version" {
  description = "Versão do Kubernetes a ser usada"
  type        = string
  default     = "1.27"
}

variable "node_size" {
  description = "Tamanho dos nós do cluster (droplet size)"
  type        = string
  default     = "s-2vcpu-2gb"
}

variable "node_count" {
  description = "Número inicial de nós no cluster"
  type        = number
  default     = 2
}

variable "min_nodes" {
  description = "Número mínimo de nós quando o auto-scaling está habilitado"
  type        = number
  default     = 1
}

variable "max_nodes" {
  description = "Número máximo de nós quando o auto-scaling está habilitado"
  type        = number
  default     = 5
}

variable "create_critical_pool" {
  description = "Se deve criar um pool adicional para cargas de trabalho críticas"
  type        = bool
  default     = false
}

variable "critical_node_size" {
  description = "Tamanho dos nós do pool crítico"
  type        = string
  default     = "s-4vcpu-8gb"
}

variable "critical_node_count" {
  description = "Número inicial de nós no pool crítico"
  type        = number
  default     = 1
}

variable "create_registry_integration" {
  description = "Se deve integrar com o Container Registry do Digital Ocean"
  type        = bool
  default     = false
}

variable "registry_name" {
  description = "Nome do Container Registry (quando a integração está habilitada)"
  type        = string
  default     = ""
}

variable "alert_emails" {
  description = "Lista de emails para receber alertas do cluster"
  type        = list(string)
  default     = []
}

variable "slack_channel" {
  description = "Canal do Slack para receber alertas (opcional)"
  type        = string
  default     = ""
}

variable "slack_webhook_url" {
  description = "URL do webhook do Slack para integração de alertas (opcional)"
  type        = string
  default     = ""
}

variable "tags" {
  description = "Lista de tags a serem aplicadas aos recursos"
  type        = list(string)
  default     = []
}