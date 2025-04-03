variable "project_id" {
  description = "ID do projeto GCP onde os recursos serão criados"
  type        = string
}

variable "name" {
  description = "Nome base para os recursos de load balancing"
  type        = string
}

variable "region" {
  description = "Região do GCP onde os recursos serão criados"
  type        = string
}

variable "network" {
  description = "Nome da rede VPC onde o load balancer será implantado"
  type        = string
}

variable "subnetwork" {
  description = "Nome da sub-rede onde o load balancer será implantado"
  type        = string
}

variable "environment" {
  description = "Ambiente de implantação (ex: dev, staging, prod)"
  type        = string
}

variable "create_external_ip" {
  description = "Define se um IP externo será criado para o load balancer"
  type        = bool
  default     = true
}

variable "enable_https" {
  description = "Define se o load balancer terá suporte a HTTPS"
  type        = bool
  default     = true
}

variable "ssl_certificates" {
  description = "Lista de certificados SSL a serem associados ao load balancer"
  type        = list(string)
  default     = []
}

variable "enable_cdn" {
  description = "Define se o CDN será habilitado para o load balancer"
  type        = bool
  default     = false
}

variable "cdn_cache_ttl" {
  description = "Tempo de vida do cache em segundos para o CDN, quando habilitado"
  type        = number
  default     = 3600
}

variable "health_check" {
  description = "Configurações do health check para o load balancer"
  type = object({
    port                = number
    protocol            = string
    request_path        = string
    check_interval_sec  = number
    timeout_sec         = number
    healthy_threshold   = number
    unhealthy_threshold = number
  })
  default = {
    port                = 80
    protocol            = "HTTP"
    request_path        = "/"
    check_interval_sec  = 5
    timeout_sec         = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

variable "backend_services" {
  description = "Configurações dos serviços de backend para o load balancer"
  type = list(object({
    name                = string
    port                = number
    protocol            = string
    timeout_sec         = number
    enable_logging      = bool
    logging_sample_rate = number
  }))
  default = []
}

variable "instance_groups" {
  description = "Lista de grupos de instâncias a serem associados ao backend service"
  type = list(object({
    name     = string
    zone     = string
    max_rate = number
    capacity = number
  }))
  default = []
}

variable "path_rules" {
  description = "Regras de caminho para encaminhamento de URL"
  type = list(object({
    paths   = list(string)
    service = string
  }))
  default = []
}

variable "ssl_policy" {
  description = "Nome da política SSL para o load balancer HTTPS"
  type        = string
  default     = null
}

variable "quic_override" {
  description = "Configura o suporte QUIC para o load balancer (NONE, ENABLE, ou DISABLE)"
  type        = string
  default     = "NONE"
  validation {
    condition     = contains(["NONE", "ENABLE", "DISABLE"], var.quic_override)
    error_message = "O valor para quic_override deve ser NONE, ENABLE ou DISABLE."
  }
}

variable "security_policy" {
  description = "Nome da política de segurança do Cloud Armor para o load balancer"
  type        = string
  default     = null
}

variable "labels" {
  description = "Mapa de labels a serem aplicados nos recursos"
  type        = map(string)
  default     = {}
}

variable "custom_request_headers" {
  description = "Lista de cabeçalhos HTTP personalizados a serem adicionados às solicitações"
  type        = list(string)
  default     = []
}

variable "custom_response_headers" {
  description = "Lista de cabeçalhos HTTP personalizados a serem adicionados às respostas"
  type        = list(string)
  default     = []
}

variable "timeouts" {
  description = "Configurações de timeout para operações de recursos do load balancer"
  type = object({
    create = string
    update = string
    delete = string
  })
  default = {
    create = "4m"
    update = "4m"
    delete = "4m"
  }
}

variable "log_config" {
  description = "Configuração de logging para o load balancer"
  type = object({
    enable      = bool
    sample_rate = number
  })
  default = {
    enable      = true
    sample_rate = 1.0
  }
}

variable "ip_version" {
  description = "Versão do IP para o load balancer (IPV4 ou IPV6)"
  type        = string
  default     = "IPV4"
  validation {
    condition     = contains(["IPV4", "IPV6"], var.ip_version)
    error_message = "O valor para ip_version deve ser IPV4 ou IPV6."
  }
}

