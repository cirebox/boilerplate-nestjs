variable "prefix" {
  description = "Prefixo a ser usado em todos os recursos do Azure para facilitar a identificação"
  type        = string
  default     = "app"
}

variable "resource_group_name" {
  description = "Nome do grupo de recursos onde o balanceador de carga será criado"
  type        = string
}

variable "location" {
  description = "Localização do Azure onde o balanceador de carga será implantado (ex: brazilsouth)"
  type        = string
}

variable "tags" {
  description = "Tags a serem aplicadas a todos os recursos"
  type        = map(string)
  default     = {}
}

# Configurações de Rede
variable "virtual_network_name" {
  description = "Nome da rede virtual onde o balanceador de carga será conectado"
  type        = string
}

variable "subnet_name" {
  description = "Nome da sub-rede onde o balanceador de carga será implantado"
  type        = string
}

variable "enable_public_ip" {
  description = "Habilitar ou não um IP público para o balanceador de carga"
  type        = bool
  default     = true
}

variable "public_ip_sku" {
  description = "SKU do IP público (Basic ou Standard)"
  type        = string
  default     = "Standard"
  validation {
    condition     = contains(["Basic", "Standard"], var.public_ip_sku)
    error_message = "O SKU do IP público deve ser 'Basic' ou 'Standard'."
  }
}

variable "allocation_method" {
  description = "Método de alocação para o IP público (Static ou Dynamic)"
  type        = string
  default     = "Static"
  validation {
    condition     = contains(["Static", "Dynamic"], var.allocation_method)
    error_message = "O método de alocação deve ser 'Static' ou 'Dynamic'."
  }
}

# Configurações do Load Balancer
variable "lb_sku" {
  description = "SKU do balanceador de carga (Basic ou Standard)"
  type        = string
  default     = "Standard"
  validation {
    condition     = contains(["Basic", "Standard"], var.lb_sku)
    error_message = "O SKU do balanceador de carga deve ser 'Basic' ou 'Standard'."
  }
}

variable "frontend_name" {
  description = "Nome da configuração de IP frontal"
  type        = string
  default     = "frontend-ip"
}

variable "backend_pool_name" {
  description = "Nome do pool de backend"
  type        = string
  default     = "backend-pool"
}

# Configurações de HTTP
variable "enable_http" {
  description = "Habilitar ou não o balanceamento HTTP (porta 80)"
  type        = bool
  default     = true
}

variable "http_port" {
  description = "Porta para o tráfego HTTP"
  type        = number
  default     = 80
}

variable "http_protocol" {
  description = "Protocolo a ser usado para o tráfego HTTP"
  type        = string
  default     = "Tcp"
  validation {
    condition     = contains(["Tcp", "Udp", "All"], var.http_protocol)
    error_message = "O protocolo deve ser 'Tcp', 'Udp' ou 'All'."
  }
}

# Configurações de HTTPS
variable "enable_https" {
  description = "Habilitar ou não o balanceamento HTTPS (porta 443)"
  type        = bool
  default     = false
}

variable "https_port" {
  description = "Porta para o tráfego HTTPS"
  type        = number
  default     = 443
}

variable "https_protocol" {
  description = "Protocolo a ser usado para o tráfego HTTPS"
  type        = string
  default     = "Tcp"
  validation {
    condition     = contains(["Tcp", "Udp", "All"], var.https_protocol)
    error_message = "O protocolo deve ser 'Tcp', 'Udp' ou 'All'."
  }
}

variable "ssl_certificate_name" {
  description = "Nome do certificado SSL a ser usado para HTTPS (se enable_https for true)"
  type        = string
  default     = ""
}

variable "key_vault_id" {
  description = "ID do Key Vault contendo o certificado SSL (opcional)"
  type        = string
  default     = ""
}

variable "ssl_certificate_data" {
  description = "Dados do certificado SSL em formato PFX (Base64) (opcional)"
  type        = string
  default     = ""
  sensitive   = true
}

variable "ssl_password" {
  description = "Senha do certificado SSL PFX (opcional)"
  type        = string
  default     = ""
  sensitive   = true
}

# Configurações de Health Probe
variable "health_probe_protocol" {
  description = "Protocolo a ser usado para verificações de integridade (Http, Https ou Tcp)"
  type        = string
  default     = "Http"
  validation {
    condition     = contains(["Http", "Https", "Tcp"], var.health_probe_protocol)
    error_message = "O protocolo de verificação de integridade deve ser 'Http', 'Https' ou 'Tcp'."
  }
}

variable "health_probe_port" {
  description = "Porta para verificações de integridade"
  type        = number
  default     = 80
}

variable "health_probe_path" {
  description = "Caminho a ser verificado para verificações de integridade HTTP/HTTPS"
  type        = string
  default     = "/"
}

variable "health_probe_interval" {
  description = "Intervalo em segundos entre verificações de integridade"
  type        = number
  default     = 15
}

variable "health_probe_unhealthy_threshold" {
  description = "Número de falhas consecutivas antes de considerar o backend não íntegro"
  type        = number
  default     = 2
}

# Configurações avançadas e otimização de custos
variable "idle_timeout_in_minutes" {
  description = "Tempo de inatividade em minutos antes que a conexão seja fechada"
  type        = number
  default     = 4
}

variable "enable_floating_ip" {
  description = "Habilitar ou não IPs flutuantes para cenários de alta disponibilidade"
  type        = string
  default     = false
}

variable "load_distribution" {
  description = "Distribuição de carga (Default, SourceIP ou SourceIPProtocol)"
  type        = string
  default     = "Default"
  validation {
    condition     = contains(["Default", "SourceIP", "SourceIPProtocol"], var.load_distribution)
    error_message = "A distribuição de carga deve ser 'Default', 'SourceIP' ou 'SourceIPProtocol'."
  }
}

variable "enable_tcp_reset" {
  description = "Habilitar ou não o reset TCP para conexões inativas"
  type        = bool
  default     = false
}

variable "disable_outbound_snat" {
  description = "Desabilitar ou não o SNAT de saída para o pool de backend"
  type        = bool
  default     = false
}

# Configurações de Monitoramento
variable "enable_diagnostic_settings" {
  description = "Habilitar ou não configurações de diagnóstico para o balanceador de carga"
  type        = bool
  default     = false
}

variable "log_analytics_workspace_id" {
  description = "ID do workspace do Log Analytics para enviar logs de diagnóstico (opcional)"
  type        = string
  default     = ""
}

variable "log_retention_days" {
  description = "Número de dias para reter logs de diagnóstico"
  type        = number
  default     = 30
}

# Configurações de WAF (Web Application Firewall) - aplicável apenas se for usado Application Gateway
variable "enable_waf" {
  description = "Habilitar ou não o WAF (Web Application Firewall) - requer Application Gateway"
  type        = bool
  default     = false
}

variable "waf_mode" {
  description = "Modo de operação do WAF (Detection ou Prevention)"
  type        = string
  default     = "Detection"
  validation {
    condition     = contains(["Detection", "Prevention"], var.waf_mode)
    error_message = "O modo do WAF deve ser 'Detection' ou 'Prevention'."
  }
}

# Variáveis específicas para Application Gateway (alternativa ao Load Balancer para HTTP/HTTPS)
variable "use_application_gateway" {
  description = "Usar Application Gateway ao invés de Load Balancer (recomendado para cargas HTTP/HTTPS)"
  type        = bool
  default     = false
}

variable "application_gateway_tier" {
  description = "Nível do Application Gateway (Standard_v2 ou WAF_v2)"
  type        = string
  default     = "Standard_v2"
  validation {
    condition     = contains(["Standard_v2", "WAF_v2"], var.application_gateway_tier)
    error_message = "O nível do Application Gateway deve ser 'Standard_v2' ou 'WAF_v2'."
  }
}

variable "application_gateway_capacity" {
  description = "Capacidade do Application Gateway (número de instâncias)"
  type        = number
  default     = 2
}

variable "cookie_based_affinity" {
  description = "Habilitar ou não afinidade baseada em cookies (Enabled ou Disabled)"
  type        = string
  default     = "Disabled"
  validation {
    condition     = contains(["Enabled", "Disabled"], var.cookie_based_affinity)
    error_message = "A afinidade baseada em cookies deve ser 'Enabled' ou 'Disabled'."
  }
}
variable "create_public_ip" {
  description = "Indica se um IP público deve ser criado para o balanceador de carga"
  type        = bool
  default     = true
}

variable "public_ip_name" {
  description = "Nome do IP público, se create_public_ip for true"
  type        = string
  default     = null
}


variable "public_ip_allocation_method" {
  description = "Método de alocação do IP público (Static ou Dynamic)"
  type        = string
  default     = "Static"

  validation {
    condition     = contains(["Static", "Dynamic"], var.public_ip_allocation_method)
    error_message = "O valor de public_ip_allocation_method deve ser 'Static' ou 'Dynamic'."
  }
}

variable "ssl_certificate" {
  description = "Configuração do certificado SSL, necessário se enable_https for true"
  type = object({
    key_vault_secret_id = string
  })
  default = null
}

variable "subnet_id" {
  description = "ID da subnet para balanceadores de carga internos"
  type        = string
  default     = null
}

variable "network_security_group_id" {
  description = "ID do grupo de segurança de rede a ser associado ao balanceador de carga"
  type        = string
  default     = null
}

