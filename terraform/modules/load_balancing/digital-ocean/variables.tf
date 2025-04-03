# Variables para configuração do Load Balancer na Digital Ocean

variable "region" {
  description = "A região onde o load balancer será implantado"
  type        = string
}

variable "project_name" {
  description = "Nome do projeto ao qual o load balancer pertence"
  type        = string
}

variable "environment" {
  description = "Ambiente onde o load balancer será implantado (dev, staging, prod)"
  type        = string
}

variable "lb_name" {
  description = "Nome do load balancer"
  type        = string
  default     = null
}

variable "vpc_uuid" {
  description = "ID da VPC onde o load balancer será implantado"
  type        = string
}

variable "droplet_ids" {
  description = "Lista de IDs de droplets para serem adicionados ao pool do load balancer"
  type        = list(string)
  default     = []
}

variable "tag_name" {
  description = "Nome da tag para selecionar droplets para o pool do load balancer (alternativa ao droplet_ids)"
  type        = string
  default     = null
}

variable "algorithm" {
  description = "Algoritmo de balanceamento de carga (round_robin, least_connections)"
  type        = string
  default     = "round_robin"

  validation {
    condition     = contains(["round_robin", "least_connections"], var.algorithm)
    error_message = "O algoritmo deve ser 'round_robin' ou 'least_connections'."
  }
}

variable "forwarding_rules" {
  description = "Lista de regras de encaminhamento para o load balancer"
  type = list(object({
    entry_protocol  = string
    entry_port      = number
    target_protocol = string
    target_port     = number
    certificate_id  = optional(string)
    tls_passthrough = optional(bool, false)
  }))
  default = []

  validation {
    condition = length([
      for rule in var.forwarding_rules : true
      if contains(["http", "https", "http2", "tcp"], rule.entry_protocol) &&
      contains(["http", "https", "http2", "tcp"], rule.target_protocol)
    ]) == length(var.forwarding_rules)
    error_message = "Protocolos suportados: http, https, http2, tcp."
  }
}

variable "healthcheck" {
  description = "Configuração do healthcheck para o load balancer"
  type = object({
    protocol                 = string
    port                     = number
    path                     = optional(string, "/")
    check_interval_seconds   = optional(number, 10)
    response_timeout_seconds = optional(number, 5)
    unhealthy_threshold      = optional(number, 3)
    healthy_threshold        = optional(number, 5)
  })
  default = {
    protocol                 = "http"
    port                     = 80
    path                     = "/"
    check_interval_seconds   = 10
    response_timeout_seconds = 5
    unhealthy_threshold      = 3
    healthy_threshold        = 5
  }

  validation {
    condition     = contains(["http", "https", "tcp"], var.healthcheck.protocol)
    error_message = "O protocolo de healthcheck deve ser 'http', 'https' ou 'tcp'."
  }
}

variable "redirect_http_to_https" {
  description = "Se verdadeiro, redireciona tráfego HTTP para HTTPS automaticamente"
  type        = bool
  default     = true
}

variable "enable_proxy_protocol" {
  description = "Ativa o protocolo proxy para preservar informações do cliente original"
  type        = bool
  default     = false
}

variable "enable_backend_keepalive" {
  description = "Habilita keepalive para conexões de backend"
  type        = bool
  default     = true
}

variable "sticky_sessions" {
  description = "Configuração para sessões persistentes (sticky sessions)"
  type = object({
    type               = optional(string, "none")
    cookie_name        = optional(string, null)
    cookie_ttl_seconds = optional(number, 3600)
  })
  default = {
    type               = "none"
    cookie_name        = null
    cookie_ttl_seconds = 3600
  }

  validation {
    condition     = contains(["cookies", "none"], var.sticky_sessions.type)
    error_message = "O tipo de sticky session deve ser 'cookies' ou 'none'."
  }
}

variable "disable_lets_encrypt_dns_records" {
  description = "Desabilita a criação automática de registros DNS para certificados Let's Encrypt"
  type        = bool
  default     = false
}

variable "firewall_rules" {
  description = "Regras de firewall específicas para o load balancer"
  type = list(object({
    source_addresses = list(string)
    source_tags      = optional(list(string), [])
    ports            = list(number)
  }))
  default = []
}

variable "tags" {
  description = "Tags para associar ao load balancer"
  type        = list(string)
  default     = []
}

