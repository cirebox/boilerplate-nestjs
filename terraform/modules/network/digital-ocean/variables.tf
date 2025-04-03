variable "environment" {
  description = "Ambiente de deploy (dev, staging, prod)"
  type        = string
}

variable "project_name" {
  description = "Nome do projeto"
  type        = string
}

variable "region" {
  description = "Região do Digital Ocean"
  type        = string
  default     = "nyc1"
}

variable "vpc_cidr" {
  description = "CIDR block para a VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "ssh_source_addresses" {
  description = "Lista de endereços IP/CIDR permitidos para conectar via SSH"
  type        = list(string)
  default     = []
}

variable "create_loadbalancer" {
  description = "Se deve criar um load balancer"
  type        = bool
  default     = false
}

variable "enable_https" {
  description = "Se deve habilitar HTTPS no load balancer"
  type        = bool
  default     = false
}

variable "certificate_id" {
  description = "ID do certificado SSL para HTTPS (quando enable_https é true)"
  type        = string
  default     = ""
}

variable "enable_ipv6" {
  description = "Se deve habilitar IPv6 na VPC"
  type        = bool
  default     = false
}

variable "additional_tags" {
  description = "Tags adicionais a serem aplicadas aos recursos"
  type        = list(string)
  default     = []
}

variable "create_domain" {
  description = "Se deve criar recursos de domínio DNS"
  type        = bool
  default     = false
}

variable "domain_name" {
  description = "Nome de domínio a ser configurado (quando create_domain é true)"
  type        = string
  default     = ""
}

variable "configure_email" {
  description = "Se deve configurar registros MX para email"
  type        = bool
  default     = false
}

variable "mx_records" {
  description = "Lista de registros MX para configuração de email"
  type = list(object({
    value    = string
    priority = number
  }))
  default = []
}

variable "txt_records" {
  description = "Lista de registros TXT para verificações de domínio"
  type = list(object({
    name  = string
    value = string
  }))
  default = []
}