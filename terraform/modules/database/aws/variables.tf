variable "environment" {
  description = "Ambiente de deploy (dev, staging, prod)"
  type        = string
}

variable "project_name" {
  description = "Nome do projeto"
  type        = string
}

variable "vpc_id" {
  description = "ID da VPC onde o RDS será criado"
  type        = string
}

variable "subnet_ids" {
  description = "Lista de IDs das subnets para o RDS"
  type        = list(string)
}

variable "engine" {
  description = "Engine do banco de dados (postgres, mysql)"
  type        = string
  default     = "postgres"
}

variable "engine_version" {
  description = "Versão do engine do banco de dados"
  type        = string
  default     = "14"
}

variable "instance_type" {
  description = "Tipo da instância RDS"
  type        = string
  default     = "db.t3.micro"
}

variable "allocated_storage" {
  description = "Tamanho inicial do armazenamento em GB"
  type        = number
  default     = 20
}

variable "max_allocated_storage" {
  description = "Tamanho máximo do armazenamento em GB para auto scaling"
  type        = number
  default     = 100
}

variable "backup_retention_days" {
  description = "Número de dias para retenção de backups"
  type        = number
  default     = 7
}

variable "multi_az" {
  description = "Habilitar Multi-AZ para alta disponibilidade"
  type        = bool
  default     = false
}

variable "deletion_protection" {
  description = "Habilitar proteção contra deleção"
  type        = bool
  default     = true
}

variable "skip_final_snapshot" {
  description = "Pular criação de snapshot final ao deletar a instância"
  type        = bool
  default     = false
}

variable "database_name" {
  description = "Nome do banco de dados inicial"
  type        = string
  default     = ""
}

variable "database_user" {
  description = "Nome do usuário principal do banco"
  type        = string
  default     = ""
}

variable "enable_replicas" {
  description = "Habilitar réplicas de leitura"
  type        = bool
  default     = false
}

variable "replica_count" {
  description = "Número de réplicas de leitura"
  type        = number
  default     = 0
}

variable "replica_instance_type" {
  description = "Tipo de instância para réplicas (se diferente da principal)"
  type        = string
  default     = ""
}

variable "tags" {
  description = "Tags para recursos AWS"
  type        = map(string)
  default     = {}
}