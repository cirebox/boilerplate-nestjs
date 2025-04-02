variable "environment" {
  description = "Ambiente de deploy (dev, staging, prod)"
  type        = string
}

variable "project_name" {
  description = "Nome do projeto"
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

variable "alert_emails" {
  description = "Lista de e-mails para receber alertas de orçamento"
  type        = list(string)
}

variable "enable_cost_explorer" {
  description = "Habilitar o Cost Explorer para análises detalhadas"
  type        = bool
  default     = true
}

variable "cost_allocation_tags" {
  description = "Lista de tags para alocação de custos"
  type        = list(string)
  default     = ["Project", "Environment"]
}

variable "tags" {
  description = "Tags a serem aplicadas a todos os recursos"
  type        = map(string)
  default     = {}
}