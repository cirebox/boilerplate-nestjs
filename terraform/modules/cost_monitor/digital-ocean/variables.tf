variable "environment" {
  description = "Ambiente (dev, staging, prod)"
  type        = string
}

variable "project_name" {
  description = "Nome do projeto"
  type        = string
}

variable "budget_threshold" {
  description = "Valor para alerta de orçamento diário"
  type        = number
  default     = 10
}

variable "monthly_budget_limit" {
  description = "Valor para alerta de orçamento mensal"
  type        = number
  default     = 300
}

variable "alert_emails" {
  description = "Lista de emails para receber alertas de orçamento"
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Tags para recursos"
  type        = list(string)
  default     = []
}

variable "create_loadbalancer" {
  description = "Flag para indicar se um load balancer será criado"
  type        = bool
  default     = true
}

# Adicionando a variável que estava faltando
variable "enable_waste_detection" {
  description = "Habilitar detecção de recursos subutilizados ou inativos"
  type        = bool
  default     = false
}

# Nova variável para estimar custos
variable "cost_estimates" {
  description = "Estimativas de custo para diferentes recursos DO"
  type = object({
    lb_small              = number
    lb_nano               = number
    droplet_basic         = number
    droplet_cpu           = number
    droplet_memory        = number
    kubernetes_basic_node = number
    kubernetes_prod_node  = number
    volume_gb             = number
  })
  default = {
    lb_small              = 12
    lb_nano               = 10
    droplet_basic         = 5
    droplet_cpu           = 20
    droplet_memory        = 24
    kubernetes_basic_node = 10
    kubernetes_prod_node  = 24
    volume_gb             = 0.10
  }
}