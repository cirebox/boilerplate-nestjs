variable "environment" {
  description = "Ambiente de deploy (dev, staging, prod)"
  type        = string
  default     = "dev"
}


variable "do_token" {
  description = "Token de acesso à API do Digital Ocean"
  type        = string
  sensitive   = true
}

variable "project_name" {
  description = "Nome do projeto"
  type        = string
  default     = "boilerplate-nestjs"
}

variable "region" {
  description = "Região do Digital Ocean a ser utilizada"
  type        = string
  default     = "nyc1"
}

variable "ssh_source_addresses" {
  description = "Lista de endereços IP/CIDR permitidos para conectar via SSH"
  type        = list(string)
  default     = []
}

variable "database_allowed_ips" {
  description = "Lista de IPs permitidos para acessar o banco de dados além da VPC"
  type        = list(string)
  default     = []
}

variable "create_registry_integration" {
  description = "Se deve criar integração com Container Registry"
  type        = bool
  default     = false
}

variable "registry_name" {
  description = "Nome do Container Registry (quando a integração está habilitada)"
  type        = string
  default     = ""
}

variable "alert_emails" {
  description = "Lista de emails para receber alertas"
  type        = list(string)
  default     = []
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