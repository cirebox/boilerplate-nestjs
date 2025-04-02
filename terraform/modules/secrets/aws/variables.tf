variable "project_name" {
  description = "Nome do projeto"
  type        = string
}

variable "environment" {
  description = "Ambiente de implantação (dev, staging, prod)"
  type        = string
}

variable "tags" {
  description = "Tags para recursos AWS"
  type        = map(string)
  default     = {}
}

variable "slack_webhook_url" {
  description = "URL de webhook do Slack para alertas"
  type        = string
  sensitive   = true
  default     = "https://hooks.slack.com/services/REAL_WEBHOOK_TOKEN_HERE"
}

variable "ms_teams_webhook_url" {
  description = "URL de webhook do Microsoft Teams para alertas"
  type        = string
  sensitive   = true
  default     = "https://outlook.office.com/webhook/REAL_TEAMS_WEBHOOK_HERE"
}

variable "pagerduty_webhook_url" {
  description = "URL de webhook do PagerDuty para alertas críticos"
  type        = string
  sensitive   = true
  default     = "https://events.pagerduty.com/integration/REAL_PAGERDUTY_KEY_HERE/enqueue"
}

variable "opsgenie_webhook_url" {
  description = "URL de webhook do OpsGenie para alertas de operações"
  type        = string
  sensitive   = true
  default     = "https://api.opsgenie.com/v1/json/webhook?apiKey=REAL_OPSGENIE_KEY_HERE"
}

variable "external_api_key" {
  description = "Chave da API externa"
  type        = string
  sensitive   = true
  default     = "external-api-key-placeholder"
}

variable "monitoring_api_token" {
  description = "Token para API de monitoramento"
  type        = string
  sensitive   = true
  default     = "monitoring-token-placeholder"
}