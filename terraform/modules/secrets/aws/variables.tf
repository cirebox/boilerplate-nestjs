variable "project_name" {
  description = "Nome do projeto"
  type        = string
}

variable "environment" {
  description = "Ambiente (dev, staging, prod)"
  type        = string
}

variable "tags" {
  description = "Tags a serem aplicadas aos recursos"
  type        = map(string)
  default     = {}
}

# Webhooks - agora com validações e sem valores padrão
variable "slack_webhook_url" {
  description = "URL do webhook do Slack para alertas"
  type        = string
  sensitive   = true
  default     = ""

  validation {
    condition     = var.slack_webhook_url == "" || can(regex("^https://hooks.slack.com/services/", var.slack_webhook_url))
    error_message = "O webhook do Slack deve começar com 'https://hooks.slack.com/services/' ou ser vazio."
  }
}

variable "ms_teams_webhook_url" {
  description = "URL do webhook do Microsoft Teams para alertas"
  type        = string
  sensitive   = true
  default     = ""

  validation {
    condition     = var.ms_teams_webhook_url == "" || can(regex("^https://", var.ms_teams_webhook_url))
    error_message = "O webhook do Microsoft Teams deve começar com 'https://' ou ser vazio."
  }
}

variable "pagerduty_webhook_url" {
  description = "URL do webhook do PagerDuty para alertas"
  type        = string
  sensitive   = true
  default     = ""

  validation {
    condition     = var.pagerduty_webhook_url == "" || can(regex("^https://", var.pagerduty_webhook_url))
    error_message = "O webhook do PagerDuty deve começar com 'https://' ou ser vazio."
  }
}

variable "opsgenie_webhook_url" {
  description = "URL do webhook do OpsGenie para alertas"
  type        = string
  sensitive   = true
  default     = ""

  validation {
    condition     = var.opsgenie_webhook_url == "" || can(regex("^https://", var.opsgenie_webhook_url))
    error_message = "O webhook do OpsGenie deve começar com 'https://' ou ser vazio."
  }
}

# API Keys - agora marcadas como sensíveis e sem valores padrão
variable "external_api_key" {
  description = "Chave da API externa"
  type        = string
  sensitive   = true
  default     = ""
}

variable "monitoring_api_token" {
  description = "Token da API de monitoramento"
  type        = string
  sensitive   = true
  default     = ""
}

# Configurações de rotação de segredos
variable "enable_secret_rotation" {
  description = "Habilita a rotação automática de segredos"
  type        = bool
  default     = false
}

variable "secret_rotation_days" {
  description = "Intervalo de rotação de segredos em dias"
  type        = number
  default     = 90

  validation {
    condition     = var.secret_rotation_days >= 30
    error_message = "O período de rotação deve ser de pelo menos 30 dias por motivos de segurança."
  }
}

# Configurações para criptografia
variable "kms_key_admin_arns" {
  description = "ARNs dos administradores da chave KMS"
  type        = list(string)
  default     = []
}

variable "use_customer_managed_key" {
  description = "Se deve usar chave gerenciada pelo cliente (CMK) para criptografia"
  type        = bool
  default     = false
}

# Configurações para backup
variable "enable_secret_backup" {
  description = "Se deve habilitar backup automático de segredos"
  type        = bool
  default     = true
}