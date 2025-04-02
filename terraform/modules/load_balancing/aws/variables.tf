# ===========================================================================
# Variáveis principais para configuração do Load Balancer na AWS
# ===========================================================================

variable "name" {
  description = "Nome do load balancer"
  type        = string
}

variable "environment" {
  description = "Ambiente onde o load balancer será implantado (ex: dev, staging, prod)"
  type        = string
}

# ===========================================================================
# Configurações de VPC e rede
# ===========================================================================

variable "vpc_id" {
  description = "ID da VPC onde o load balancer será implantado"
  type        = string
}

variable "subnet_ids" {
  description = "Lista de IDs de sub-redes onde o load balancer será implantado"
  type        = list(string)
}

variable "security_group_ids" {
  description = "Lista de IDs de grupos de segurança para associar ao load balancer"
  type        = list(string)
  default     = []
}

variable "create_security_group" {
  description = "Determina se um grupo de segurança deve ser criado para o load balancer"
  type        = bool
  default     = true
}

variable "security_group_rules" {
  description = "Regras para o grupo de segurança do load balancer, no formato {from_port, to_port, protocol, cidr_blocks}"
  type = list(object({
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_blocks = list(string)
    description = string
  }))
  default = [
    {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
      description = "HTTP de qualquer origem"
    },
    {
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
      description = "HTTPS de qualquer origem"
    }
  ]
}

# ===========================================================================
# Configurações do Load Balancer
# ===========================================================================

variable "load_balancer_type" {
  description = "Tipo do load balancer (application, network, gateway)"
  type        = string
  default     = "application"
}

variable "internal" {
  description = "Determina se o load balancer é interno (true) ou voltado para a internet (false)"
  type        = bool
  default     = false
}

variable "enable_deletion_protection" {
  description = "Determina se a proteção contra exclusão está habilitada"
  type        = bool
  default     = false
}

variable "idle_timeout" {
  description = "Tempo em segundos que uma conexão pode permanecer ociosa"
  type        = number
  default     = 60
}

variable "enable_cross_zone_load_balancing" {
  description = "Habilita o balanceamento de carga entre zonas de disponibilidade"
  type        = bool
  default     = true
}

variable "enable_http2" {
  description = "Habilita o protocolo HTTP/2"
  type        = bool
  default     = true
}

variable "ip_address_type" {
  description = "Tipo de endereço IP do load balancer (ipv4 ou dualstack)"
  type        = string
  default     = "ipv4"
}

# ===========================================================================
# Configurações de Health Check
# ===========================================================================

variable "health_check" {
  description = "Configurações do health check para o target group padrão"
  type = object({
    enabled             = bool
    interval            = number
    path                = string
    port                = string
    protocol            = string
    timeout             = number
    healthy_threshold   = number
    unhealthy_threshold = number
    matcher             = string
  })
  default = {
    enabled             = true
    interval            = 30
    path                = "/"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
    matcher             = "200-299"
  }
}

# ===========================================================================
# Configurações de listeners
# ===========================================================================

variable "http_port" {
  description = "Porta HTTP para o listener"
  type        = number
  default     = 80
}

variable "https_port" {
  description = "Porta HTTPS para o listener"
  type        = number
  default     = 443
}

variable "http_enabled" {
  description = "Habilita o listener HTTP"
  type        = bool
  default     = true
}

variable "https_enabled" {
  description = "Habilita o listener HTTPS"
  type        = bool
  default     = false
}

variable "http_redirect" {
  description = "Redireciona tráfego HTTP para HTTPS"
  type        = bool
  default     = false
}

variable "certificate_arn" {
  description = "ARN do certificado SSL/TLS para o listener HTTPS"
  type        = string
  default     = ""
}

# ===========================================================================
# Configurações de Target Groups
# ===========================================================================

variable "target_groups" {
  description = "Lista de target groups para o load balancer"
  type = list(object({
    name             = string
    backend_protocol = string
    backend_port     = number
    target_type      = string
    vpc_id           = string
    health_check     = map(any)
    targets          = list(map(any))
    tags             = map(string)
  }))
  default = []
}

variable "default_target_group_port" {
  description = "Porta padrão para o target group"
  type        = number
  default     = 80
}

variable "stickiness" {
  description = "Configurações de stickiness para o target group padrão"
  type = object({
    enabled         = bool
    type            = string
    cookie_duration = number
  })
  default = {
    enabled         = false
    type            = "lb_cookie"
    cookie_duration = 86400 # 1 dia
  }
}

# ===========================================================================
# Configurações de logs de acesso
# ===========================================================================

variable "access_logs" {
  description = "Configurações para logs de acesso do load balancer"
  type = object({
    enabled       = bool
    bucket        = string
    prefix        = string
    retention_days = number
  })
  default = {
    enabled       = false
    bucket        = ""
    prefix        = ""
    retention_days = 30
  }
}

# ===========================================================================
# Tags
# ===========================================================================

variable "tags" {
  description = "Tags a serem aplicadas a todos os recursos"
  type        = map(string)
  default     = {}
}

# ===========================================================================
# Variáveis adicionais
# ===========================================================================

variable "deregistration_delay" {
  description = "Tempo em segundos antes de cancelar o registro de destinos"
  type        = number
  default     = 300
}

variable "slow_start" {
  description = "Tempo em segundos durante o qual o load balancer envia uma quantidade reduzida de solicitações para um destino recém-registrado"
  type        = number
  default     = 0
}

variable "load_balancing_algorithm_type" {
  description = "Determina como o load balancer seleciona destinos. Valores possíveis: round_robin, least_outstanding_requests"
  type        = string
  default     = "round_robin"
}

