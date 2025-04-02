# ---------------------------------------------------------------------------------------------------------------------
# VARIÁVEIS OBRIGATÓRIAS
# Estas variáveis devem ser definidas para que o módulo funcione corretamente
# ---------------------------------------------------------------------------------------------------------------------

variable "provider_name" {
  description = "Nome do provedor de nuvem a ser utilizado (aws, digitalocean, gcp, azure)"
  type        = string
  validation {
    condition     = contains(["aws", "digitalocean", "gcp", "azure"], var.provider_name)
    error_message = "O valor de provider_name deve ser um dos seguintes: aws, digitalocean, gcp, azure."
  }
}

variable "name" {
  description = "Nome do load balancer"
  type        = string
}

variable "region" {
  description = "Região onde o load balancer será criado"
  type        = string
}

variable "vpc_id" {
  description = "ID da VPC onde o load balancer será implantado"
  type        = string
  default     = ""
}

variable "subnet_ids" {
  description = "Lista de IDs de subnets onde o load balancer será implantado (AWS e GCP)"
  type        = list(string)
  default     = []
}

variable "droplet_ids" {
  description = "Lista de IDs de droplets para associar ao load balancer (somente Digital Ocean)"
  type        = list(string)
  default     = []
}

variable "target_groups" {
  description = "Configuração dos grupos de destino"
  type = list(object({
    name             = string
    port             = number
    protocol         = string
    target_type      = optional(string, "instance")
    health_check     = optional(map(any), {})
    targets          = optional(list(string), [])
    target_instances = optional(list(string), [])
  }))
  default = []
}

# ---------------------------------------------------------------------------------------------------------------------
# VARIÁVEIS OPCIONAIS
# Estas variáveis têm valores padrão, mas podem ser substituídas pelo usuário
# ---------------------------------------------------------------------------------------------------------------------

variable "algorithm" {
  description = "Algoritmo de balanceamento a ser utilizado (round_robin, least_connections, etc)"
  type        = string
  default     = "round_robin"
}

variable "forwarding_rules" {
  description = "Regras de encaminhamento para o load balancer"
  type = list(object({
    entry_port      = number
    entry_protocol  = string
    target_port     = number
    target_protocol = string
    certificate_id  = optional(string, null)
    tls_passthrough = optional(bool, false)
  }))
  default = [
    {
      entry_port      = 80
      entry_protocol  = "http"
      target_port     = 80
      target_protocol = "http"
    }
  ]
}

variable "healthcheck" {
  description = "Configuração do health check para o load balancer"
  type = object({
    port                = optional(number, 80)
    protocol            = optional(string, "http")
    path                = optional(string, "/")
    check_interval_sec  = optional(number, 10)
    timeout_sec         = optional(number, 5)
    healthy_threshold   = optional(number, 3)
    unhealthy_threshold = optional(number, 3)
  })
  default = {
    port                = 80
    protocol            = "http"
    path                = "/"
    check_interval_sec  = 10
    timeout_sec         = 5
    healthy_threshold   = 3
    unhealthy_threshold = 3
  }
}

variable "sticky_sessions" {
  description = "Configuração de sessões persistentes (sticky sessions)"
  type = object({
    enabled              = optional(bool, false)
    type                 = optional(string, "cookies")
    cookie_name          = optional(string, "lb_session")
    cookie_ttl_seconds   = optional(number, 3600)
  })
  default = {
    enabled            = false
    type               = "cookies"
    cookie_name        = "lb_session"
    cookie_ttl_seconds = 3600
  }
}

variable "redirect_http_to_https" {
  description = "Habilitar redirecionamento automático de HTTP para HTTPS"
  type        = bool
  default     = false
}

variable "enable_proxy_protocol" {
  description = "Habilitar o protocolo de proxy para preservar informações de cliente"
  type        = bool
  default     = false
}

variable "enable_backend_keepalive" {
  description = "Habilitar conexões keepalive para backends"
  type        = bool
  default     = false
}

variable "ssl_certificate_id" {
  description = "ID do certificado SSL a ser utilizado (para HTTPS)"
  type        = string
  default     = ""
}

variable "tags" {
  description = "Tags a serem aplicadas no load balancer"
  type        = map(string)
  default     = {}
}

variable "internal" {
  description = "Indica se o load balancer deve ser interno (privado) ou externo (público)"
  type        = bool
  default     = false
}

variable "idle_timeout" {
  description = "Tempo limite em segundos para conexões ociosas"
  type        = number
  default     = 60
}

variable "security_groups" {
  description = "Lista de security groups para associar ao load balancer (AWS)"
  type        = list(string)
  default     = []
}

variable "enable_deletion_protection" {
  description = "Habilitar proteção contra exclusão acidental"
  type        = bool
  default     = true
}

variable "access_logs" {
  description = "Configuração para logs de acesso"
  type = object({
    enabled       = optional(bool, false)
    bucket        = optional(string, "")
    prefix        = optional(string, "lb-logs")
    retention_days = optional(number, 30)
  })
  default = {
    enabled       = false
    bucket        = ""
    prefix        = "lb-logs"
    retention_days = 30
  }
}

variable "cloudwatch_monitoring" {
  description = "Habilitar monitoramento via CloudWatch (AWS)"
  type        = bool
  default     = true
}

variable "firewall_rules" {
  description = "Regras de firewall para o load balancer"
  type = list(object({
    source_ips   = list(string)
    port_range   = string
    protocol     = string
    description  = optional(string, "")
  }))
  default = []
}

# ---------------------------------------------------------------------------------------------------------------------
# VARIÁVEIS ESPECÍFICAS PARA AZURE
# Estas variáveis são necessárias apenas quando provider_name = "azure"
# ---------------------------------------------------------------------------------------------------------------------

variable "resource_group_name" {
  description = "Nome do resource group onde o load balancer será criado (somente Azure)"
  type        = string
  default     = ""
}

variable "azure_location" {
  description = "Região do Azure onde o load balancer será criado (somente Azure)"
  type        = string
  default     = ""
}

variable "azure_sku" {
  description = "SKU do Azure Load Balancer: Basic ou Standard (somente Azure)"
  type        = string
  default     = "Standard"
  validation {
    condition     = contains(["Basic", "Standard"], var.azure_sku)
    error_message = "O valor de azure_sku deve ser 'Basic' ou 'Standard'."
  }
}

variable "azure_tier" {
  description = "Tier do Azure Application Gateway: Standard_v2, WAF_v2 (somente Azure)"
  type        = string
  default     = "Standard_v2"
  validation {
    condition     = contains(["Standard_v2", "WAF_v2"], var.azure_tier)
    error_message = "O valor de azure_tier deve ser 'Standard_v2' ou 'WAF_v2'."
  }
}

variable "azure_capacity_units" {
  description = "Número de unidades de capacidade para o Application Gateway (somente Azure)"
  type        = number
  default     = 2
}

variable "azure_autoscale" {
  description = "Configuração de autoscale para o Application Gateway (somente Azure)"
  type = object({
    enabled  = bool
    min_capacity = number
    max_capacity = number
  })
  default = {
    enabled      = true
    min_capacity = 2
    max_capacity = 10
  }
}

variable "azure_waf_enabled" {
  description = "Habilitar Web Application Firewall (WAF) (somente Azure)"
  type        = bool
  default     = false
}

variable "azure_waf_configuration" {
  description = "Configuração do WAF, quando habilitado (somente Azure)"
  type = object({
    firewall_mode            = string
    rule_set_type            = string
    rule_set_version         = string
    file_upload_limit_mb     = optional(number, 100)
    request_body_check       = optional(bool, true)
    max_request_body_size_kb = optional(number, 128)
  })
  default = {
    firewall_mode            = "Prevention"
    rule_set_type            = "OWASP"
    rule_set_version         = "3.2"
    file_upload_limit_mb     = 100
    request_body_check       = true
    max_request_body_size_kb = 128
  }
}

variable "azure_frontend_ip_configuration" {
  description = "Configuração de IP público/privado para o load balancer (somente Azure)"
  type = object({
    public_ip_name       = optional(string, "")
    create_public_ip     = optional(bool, true)
    private_ip_address   = optional(string, "")
    private_ip_allocation = optional(string, "Dynamic")
  })
  default = {
    create_public_ip     = true
    private_ip_allocation = "Dynamic"
  }
}
