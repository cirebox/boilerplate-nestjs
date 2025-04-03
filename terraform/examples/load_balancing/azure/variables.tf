variable "resource_group_name" {
  description = "Nome do grupo de recursos do Azure onde o Load Balancer será criado"
  type        = string
}

variable "location" {
  description = "Região do Azure onde o Load Balancer será implantado (ex: brazilsouth, eastus)"
  type        = string
}

variable "lb_name" {
  description = "Nome para o Load Balancer"
  type        = string
  default     = "app-loadbalancer"
}

variable "lb_type" {
  description = "Tipo do Load Balancer do Azure: 'public' para Load Balancer público ou 'private' para interno"
  type        = string
  default     = "public"
  validation {
    condition     = contains(["public", "private"], var.lb_type)
    error_message = "O tipo de Load Balancer deve ser 'public' ou 'private'."
  }
}

variable "sku" {
  description = "SKU do Load Balancer: 'Basic' ou 'Standard'"
  type        = string
  default     = "Standard"
  validation {
    condition     = contains(["Basic", "Standard"], var.sku)
    error_message = "A SKU deve ser 'Basic' ou 'Standard'."
  }
}

variable "subnet_id" {
  description = "ID da subnet para o Load Balancer interno (obrigatório apenas se lb_type for 'private')"
  type        = string
  default     = null
}

variable "frontend_ip_configuration_name" {
  description = "Nome para a configuração de IP Frontend do Load Balancer"
  type        = string
  default     = "frontend-ip"
}

variable "frontend_private_ip_address" {
  description = "Endereço IP privado estático para o Load Balancer interno (opcional)"
  type        = string
  default     = null
}

variable "frontend_private_ip_address_allocation" {
  description = "Método de alocação do IP privado: 'Static' ou 'Dynamic'"
  type        = string
  default     = "Dynamic"
  validation {
    condition     = contains(["Static", "Dynamic"], var.frontend_private_ip_address_allocation)
    error_message = "O método de alocação deve ser 'Static' ou 'Dynamic'."
  }
}

variable "public_ip_name" {
  description = "Nome do IP público a ser criado para o Load Balancer público"
  type        = string
  default     = "lb-public-ip"
}

variable "public_ip_allocation_method" {
  description = "Método de alocação do IP público: 'Static' ou 'Dynamic'"
  type        = string
  default     = "Static"
  validation {
    condition     = contains(["Static", "Dynamic"], var.public_ip_allocation_method)
    error_message = "O método de alocação deve ser 'Static' ou 'Dynamic'."
  }
}

variable "public_ip_sku" {
  description = "SKU do IP público: 'Basic' ou 'Standard' (deve corresponder à SKU do Load Balancer)"
  type        = string
  default     = "Standard"
  validation {
    condition     = contains(["Basic", "Standard"], var.public_ip_sku)
    error_message = "A SKU do IP público deve ser 'Basic' ou 'Standard'."
  }
}

variable "backend_address_pool_name" {
  description = "Nome para o pool de endereços backend do Load Balancer"
  type        = string
  default     = "backend-pool"
}

variable "health_probe_name" {
  description = "Nome para o health probe do Load Balancer"
  type        = string
  default     = "health-probe"
}

variable "health_probe_protocol" {
  description = "Protocolo para o health probe: 'Http', 'Https', ou 'Tcp'"
  type        = string
  default     = "Http"
  validation {
    condition     = contains(["Http", "Https", "Tcp"], var.health_probe_protocol)
    error_message = "O protocolo do health probe deve ser 'Http', 'Https' ou 'Tcp'."
  }
}

variable "health_probe_port" {
  description = "Porta para o health probe"
  type        = number
  default     = 80
}

variable "health_probe_request_path" {
  description = "Caminho para o health probe (somente para probes HTTP/HTTPS)"
  type        = string
  default     = "/"
}

variable "health_probe_interval" {
  description = "Intervalo em segundos entre health probes"
  type        = number
  default     = 15
}

variable "health_probe_unhealthy_threshold" {
  description = "Número de falhas consecutivas necessárias para considerar um backend não saudável"
  type        = number
  default     = 2
}

variable "lb_rules" {
  description = "Lista de regras de balanceamento de carga a serem criadas"
  type = list(object({
    name                    = string
    protocol                = string
    frontend_port           = number
    backend_port            = number
    disable_outbound_snat   = optional(bool, false)
    enable_floating_ip      = optional(bool, false)
    idle_timeout_in_minutes = optional(number, 4)
    load_distribution       = optional(string, "Default")
  }))
  default = [
    {
      name          = "http-rule"
      protocol      = "Tcp"
      frontend_port = 80
      backend_port  = 80
    }
  ]
}

variable "nat_rules" {
  description = "Lista de regras NAT a serem criadas"
  type = list(object({
    name                    = string
    protocol                = string
    frontend_port           = number
    backend_port            = number
    idle_timeout_in_minutes = optional(number, 4)
    enable_floating_ip      = optional(bool, false)
  }))
  default = []
}

variable "outbound_rules" {
  description = "Lista de regras de saída a serem criadas"
  type = list(object({
    name                     = string
    protocol                 = string
    allocated_outbound_ports = optional(number, 1024)
    idle_timeout_in_minutes  = optional(number, 4)
  }))
  default = []
}

variable "enable_waf" {
  description = "Habilitar Web Application Firewall para o Application Gateway (disponível apenas se estiver usando Application Gateway)"
  type        = bool
  default     = false
}

variable "waf_mode" {
  description = "Modo do WAF: 'Detection' ou 'Prevention'"
  type        = string
  default     = "Detection"
  validation {
    condition     = contains(["Detection", "Prevention"], var.waf_mode)
    error_message = "O modo do WAF deve ser 'Detection' ou 'Prevention'."
  }
}

variable "tags" {
  description = "Tags a serem aplicadas em todos os recursos"
  type        = map(string)
  default     = {}
}

variable "enable_deletion_protection" {
  description = "Habilitar proteção contra exclusão acidental do Load Balancer"
  type        = bool
  default     = true
}

variable "enable_https" {
  description = "Habilitar HTTPS no Load Balancer"
  type        = bool
  default     = false
}

variable "ssl_certificate_path" {
  description = "Caminho para o certificado SSL (usado apenas se enable_https = true)"
  type        = string
  default     = null
}

variable "ssl_certificate_password" {
  description = "Senha para o certificado SSL (usado apenas se enable_https = true)"
  type        = string
  default     = null
  sensitive   = true
}

variable "enable_diagnostic_settings" {
  description = "Habilitar configurações de diagnóstico para o Load Balancer"
  type        = bool
  default     = false
}

variable "log_analytics_workspace_id" {
  description = "ID do workspace do Log Analytics para enviar diagnósticos (usado apenas se enable_diagnostic_settings = true)"
  type        = string
  default     = null
}

variable "zones" {
  description = "Lista de zonas de disponibilidade para o Load Balancer (somente para SKU Standard)"
  type        = list(string)
  default     = null
}

