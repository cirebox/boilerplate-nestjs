variable "environment" {
  description = "Ambiente de deploy (dev, staging, prod)"
  type        = string
}

variable "project_name" {
  description = "Nome do projeto"
  type        = string
}

variable "region" {
  description = "Região AWS"
  type        = string
  default     = "us-east-1"
}

variable "vpc_cidr" {
  description = "CIDR block para a VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "subnet_count" {
  description = "Número de subnets (públicas e privadas) a serem criadas"
  type        = number
  default     = 3
}

variable "availability_zones" {
  description = "Lista de zonas de disponibilidade onde as subnets serão criadas"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b", "us-east-1c"]
}

variable "create_nat_gateway" {
  description = "Se deve criar um NAT Gateway para permitir tráfego de saída das subnets privadas"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags a serem aplicadas a todos os recursos"
  type        = map(string)
  default     = {}
}