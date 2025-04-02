variable "environment" {
  description = "Ambiente de deploy (dev, staging, prod)"
  type        = string
}

variable "project_name" {
  description = "Nome do projeto"
  type        = string
}

variable "engine" {
  description = "Engine do banco de dados (pg, mysql, mongodb, redis)"
  type        = string
  default     = "pg"
}

variable "engine_version" {
  description = "Versão do engine do banco de dados"
  type        = string
  default     = "14"
}

variable "instance_type" {
  description = "Tamanho da instância de banco de dados"
  type        = string
  default     = "db-s-1vcpu-1gb"
}

variable "region" {
  description = "Região do Digital Ocean"
  type        = string
}

variable "node_count" {
  description = "Número de nós no cluster de banco de dados (para produção)"
  type        = number
  default     = 2
}

variable "vpc_id" {
  description = "ID da VPC onde o banco de dados será implantado"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR da VPC para configuração de firewall"
  type        = string
}

variable "database_name" {
  description = "Nome do banco de dados"
  type        = string
  default     = ""
}

variable "database_user" {
  description = "Nome de usuário para o banco de dados"
  type        = string
  default     = ""
}

variable "allowed_ips" {
  description = "Lista de IPs permitidos para acessar o banco de dados (apenas para dev/staging)"
  type        = list(string)
  default     = []
}