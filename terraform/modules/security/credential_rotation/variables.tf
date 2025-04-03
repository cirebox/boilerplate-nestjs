variable "project_name" {
  description = "Nome do projeto ao qual este módulo de rotação de credenciais está associado"
  type        = string
}

variable "environment" {
  description = "Ambiente de execução (dev, staging, prod)"
  type        = string
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "O ambiente deve ser um dos seguintes valores: dev, staging, prod."
  }
}

variable "initial_token" {
  description = "Token inicial usado para autenticação. Este token será rotacionado conforme o cronograma definido"
  type        = string
  sensitive   = true
}

variable "rotation_schedule" {
  description = "Expressão cron que define quando as credenciais serão rotacionadas"
  type        = string
  default     = "0 0 1 * *" # Por padrão, rotaciona no primeiro dia de cada mês
}

variable "token_expiration_days" {
  description = "Número de dias até que um token expire após sua criação"
  type        = number
  default     = 30
}

variable "notification_email" {
  description = "Endereço de email para enviar notificações sobre rotação de credenciais"
  type        = string
  default     = ""
}

variable "notification_webhook_url" {
  description = "URL do webhook para enviar notificações sobre rotação de credenciais"
  type        = string
  default     = ""
}

variable "use_aws_secrets_manager" {
  description = "Se verdadeiro, utiliza o AWS Secrets Manager para armazenar as credenciais rotacionadas"
  type        = bool
  default     = false
}

variable "use_vault" {
  description = "Se verdadeiro, utiliza o HashiCorp Vault para armazenar as credenciais rotacionadas"
  type        = bool
  default     = false
}

variable "vault_address" {
  description = "Endereço do servidor HashiCorp Vault, necessário quando use_vault=true"
  type        = string
  default     = ""
}

variable "vault_token" {
  description = "Token de autenticação para o HashiCorp Vault, necessário quando use_vault=true"
  type        = string
  default     = ""
  sensitive   = true
}

variable "aws_region" {
  description = "Região AWS onde os recursos de rotação serão criados, necessário quando use_aws_secrets_manager=true"
  type        = string
  default     = "us-east-1"
}

variable "rotation_function_timeout" {
  description = "Tempo máximo em segundos para a execução da função de rotação"
  type        = number
  default     = 300
}

variable "rotation_function_memory" {
  description = "Quantidade de memória em MB alocada para a função de rotação"
  type        = number
  default     = 128
}

variable "tags" {
  description = "Tags a serem aplicadas a todos os recursos criados por este módulo"
  type        = map(string)
  default     = {}
}

