variable "environment" {
  description = "Ambiente de deploy (dev, staging, prod)"
  type        = string
}

variable "project_name" {
  description = "Nome do projeto"
  type        = string
}

variable "region" {
  description = "Região GCP"
  type        = string
  default     = "us-central1"
}

variable "vpc_cidr" {
  description = "CIDR block para a VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "create_nat_gateway" {
  description = "Se deve criar um Cloud NAT para permitir tráfego de saída das subnets privadas"
  type        = bool
  default     = false
}

variable "subnet_count" {
  description = "Número de subnets a serem criadas"
  type        = number
  default     = 1
}

variable "tags" {
  description = "Tags a serem aplicadas a todos os recursos"
  type        = map(string)
  default     = {}
}