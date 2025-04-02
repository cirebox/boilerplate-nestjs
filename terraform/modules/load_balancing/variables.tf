/**
 * # Módulo de Load Balancing
 * 
 * Este módulo abstrato fornece uma interface unificada para criar recursos de balanceamento de carga
 * em diferentes provedores de nuvem (AWS, GCP, Azure e DigitalOcean).
 */

# Variáveis comuns para todos os provedores
variable "name" {
  description = "Nome do load balancer"
  type        = string
}

variable "environment" {
  description = "Ambiente de implantação (ex: dev, staging, prod)"
  type        = string
}

variable "tags" {
  description = "Tags para classificar e organizar os recursos"
  type        = map(string)
  default     = {}
}

variable "provider_name" {
  description = "Provedor de nuvem a ser utilizado (aws, gcp, azure, digitalocean)"
  type        = string
  
  validation {
    condition     = contains(["aws", "gcp", "azure", "digitalocean"], var.provider_name)
    error_message = "Provedor inválido. Os valores permitidos são: aws, gcp, azure, digitalocean."
  }
}

variable "region" {
  description = "Região onde o load balancer será implantado"
  type        = string
}

variable "enable_https" {
  description = "Habilitar HTTPS no load balancer"
  type        = bool
  default     = true
}

variable "enable_http" {
  description = "Habilitar HTTP no load balancer"
  type        = bool
  default     = true
}

variable "http_port" {
  description = "Porta para o tráfego HTTP"
  type        = number
  default     = 80
}

variable "https_port" {
  description = "Porta para o tráfego HTTPS"
  type        = number
  default     = 443
}

variable "health_check_path" {
  description = "Caminho para verificação de saúde do serviço"
  type        = string
  default     = "/health"
}

variable "health_check_port" {
  description = "Porta para verificação de saúde do serviço"
  type        = number
  default     = 80
}

variable "health_check_protocol" {
  description = "Protocolo para verificação de saúde (http ou https)"
  type        = string
  default     = "http"
  
  validation {
    condition     = contains(["http", "https"], var.health_check_protocol)
    error_message = "Protocolo inválido. Os valores permitidos são: http, https."
  }
}

variable "health_check_interval" {
  description = "Intervalo entre verificações de saúde (segundos)"
  type        = number
  default     = 30
}

variable "health_check_timeout" {
  description = "Tempo limite para verificação de saúde (segundos)"
  type        = number
  default     = 5
}

variable "health_check_healthy_threshold" {
  description = "Número de verificações bem-sucedidas para considerar o serviço saudável"
  type        = number
  default     = 3
}

variable "health_check_unhealthy_threshold" {
  description = "Número de verificações com falha para considerar o serviço não saudável"
  type        = number
  default     = 3
}

variable "target_service_port" {
  description = "Porta do serviço de destino para o qual o tráfego será encaminhado"
  type        = number
  default     = 3000
}

# Variáveis específicas para AWS
variable "aws_vpc_id" {
  description = "ID da VPC na AWS onde o load balancer será implantado"
  type        = string
  default     = ""
}

variable "aws_subnet_ids" {
  description = "IDs das subnets na AWS onde o load balancer será implantado"
  type        = list(string)
  default     = []
}

variable "aws_certificate_arn" {
  description = "ARN do certificado SSL no AWS Certificate Manager"
  type        = string
  default     = ""
}

variable "aws_lb_type" {
  description = "Tipo de load balancer na AWS (application, network, gateway)"
  type        = string
  default     = "application"
  
  validation {
    condition     = contains(["application", "network", "gateway"], var.aws_lb_type)
    error_message = "Tipo de load balancer inválido. Os valores permitidos são: application, network, gateway."
  }
}

variable "aws_enable_cross_zone_load_balancing" {
  description = "Habilitar balanceamento de carga entre zonas de disponibilidade na AWS"
  type        = bool
  default     = true
}

variable "aws_enable_deletion_protection" {
  description = "Habilitar proteção contra exclusão na AWS"
  type        = bool
  default     = false
}

variable "aws_enable_access_logs" {
  description = "Habilitar logs de acesso na AWS"
  type        = bool
  default     = false
}

variable "aws_access_logs_bucket" {
  description = "Nome do bucket S3 para armazenar logs de acesso na AWS"
  type        = string
  default     = ""
}

# Variáveis específicas para GCP
variable "gcp_project_id" {
  description = "ID do projeto no GCP"
  type        = string
  default     = ""
}

variable "gcp_network" {
  description = "Nome da rede no GCP"
  type        = string
  default     = "default"
}

variable "gcp_subnetwork" {
  description = "Nome da sub-rede no GCP"
  type        = string
  default     = ""
}

variable "gcp_ssl_certificates" {
  description = "IDs dos certificados SSL no GCP"
  type        = list(string)
  default     = []
}

variable "gcp_backend_service_protocol" {
  description = "Protocolo do serviço de backend no GCP (HTTP, HTTPS, HTTP2, TCP, SSL)"
  type        = string
  default     = "HTTP"
  
  validation {
    condition     = contains(["HTTP", "HTTPS", "HTTP2", "TCP", "SSL"], var.gcp_backend_service_protocol)
    error_message = "Protocolo inválido. Os valores permitidos são: HTTP, HTTPS, HTTP2, TCP, SSL."
  }
}

variable "gcp_enable_cdn" {
  description = "Habilitar CDN no GCP"
  type        = bool
  default     = false
}

variable "gcp_enable_logging" {
  description = "Habilitar logging no GCP"
  type        = bool
  default     = false
}

# Variáveis específicas para Azure
variable "azure_resource_group_name" {
  description = "Nome do grupo de recursos no Azure"
  type        = string
  default     = ""
}

variable "azure_vnet_name" {
  description = "Nome da rede virtual no Azure"
  type        = string
  default     = ""
}

variable "azure_subnet_name" {
  description = "Nome da sub-rede no Azure"
  type        = string
  default     = ""
}

variable "azure_private_ip_address_allocation" {
  description = "Método de alocação de IP privado no Azure (Static, Dynamic)"
  type        = string
  default     = "Dynamic"
  
  validation {
    condition     = contains(["Static", "Dynamic"], var.azure_private_ip_address_allocation)
    error_message = "Método de alocação inválido. Os valores permitidos são: Static, Dynamic."
  }
}

variable "azure_lb_sku" {
  description = "SKU do load balancer no Azure (Basic, Standard)"
  type        = string
  default     = "Standard"
  
  validation {
    condition     = contains(["Basic", "Standard"], var.azure_lb_sku)
    error_message = "SKU inválido. Os valores permitidos são: Basic, Standard."
  }
}

variable "azure_enable_floating_ip" {
  description = "Habilitar IP flutuante no Azure"
  type        = bool
  default     = false
}

variable "azure_certificate_name" {
  description = "Nome do certificado no Azure Key Vault"
  type        = string
  default     = ""
}

variable "azure_key_vault_id" {
  description = "ID do Key Vault no Azure onde o certificado está armazenado"
  type        = string
  default     = ""
}

# Variáveis específicas para DigitalOcean
variable "do_vpc_id" {
  description = "ID da VPC no DigitalOcean"
  type        = string
  default     = ""
}

variable "do_droplet_ids" {
  description = "IDs dos droplets do DigitalOcean para o balanceador de carga"
  type        = list(string)
  default     = []
}

variable "do_sticky_sessions" {
  description = "Configuração de sessões persistentes para o DigitalOcean"
  type = object({
    enabled               = bool
    cookie_name           = string
    cookie_ttl_seconds    = number
  })
  default = {
    enabled               = false
    cookie_name           = "lb_session"
    cookie_ttl_seconds    = 3600
  }
}

variable "do_redirect_http_to_https" {
  description = "Redirecionar tráfego HTTP para HTTPS no DigitalOcean"
  type        = bool
  default     = false
}

variable "do_enable_proxy_protocol" {
  description = "Habilitar o protocolo proxy no DigitalOcean"
  type        = bool
  default     = false
}

variable "do_enable_backend_keepalive" {
  description = "Habilitar keepalive do backend no DigitalOcean"
  type        = bool
  default     = false
}

variable "do_certificate_id" {
  description = "ID do certificado no DigitalOcean"
  type        = string
  default     = ""
}

variable "do_algorithm" {
  description = "Algoritmo de balanceamento de carga no DigitalOcean (round_robin, least_connections)"
  type        = string
  default     = "round_robin"
  
  validation {
    condition     = contains(["round_robin", "least_connections"], var.do_algorithm)
    error_message = "Algoritmo inválido. Os valores permitidos são: round_robin, least_connections."
  }
}

