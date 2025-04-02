variable "environment" {
  description = "Ambiente de deploy (dev, staging, prod)"
  type        = string
}

variable "project_name" {
  description = "Nome do projeto"
  type        = string
}

variable "project_id" {
  description = "ID do projeto GCP"
  type        = string
}

variable "region" {
  description = "Região GCP"
  type        = string
  default     = "us-central1"
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
  description = "Tipo de instância para o Cloud SQL"
  type        = string
  default     = "db-f1-micro" # Tipo mais econômico para desenvolvimento
}

variable "allocated_storage" {
  description = "Tamanho inicial do armazenamento em GB"
  type        = number
  default     = 10
}

variable "max_allocated_storage" {
  description = "Tamanho máximo do armazenamento em GB para auto-scaling"
  type        = number
  default     = 100
}

variable "storage_gb" {
  description = "Tamanho do armazenamento em GB (depreciado, use allocated_storage)"
  type        = number
  default     = 10
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

variable "backup_retention_days" {
  description = "Número de dias para retenção de backups"
  type        = number
  default     = 7
}

variable "deletion_protection" {
  description = "Proteger o banco contra exclusão acidental"
  type        = bool
  default     = true
}

variable "multi_az" {
  description = "Habilitar implantação Multi-AZ para alta disponibilidade"
  type        = bool
  default     = false
}

variable "vpc_self_link" {
  description = "Self-link da VPC onde o banco de dados será implantado"
  type        = string
}

variable "enable_replicas" {
  description = "Habilitar réplicas de leitura"
  type        = bool
  default     = false
}

variable "replica_count" {
  description = "Número de réplicas de leitura a serem criadas"
  type        = number
  default     = 1
}

variable "replica_instance_type" {
  description = "Tipo de instância para as réplicas de leitura (se diferente da instância principal)"
  type        = string
  default     = ""
}

variable "authorized_networks" {
  description = "Lista de redes autorizadas a se conectar diretamente ao banco de dados (apenas para ambientes de desenvolvimento)"
  type = list(object({
    name = string
    cidr = string
  }))
  default = []
}

variable "tags" {
  description = "Tags a serem aplicadas a todos os recursos"
  type        = map(string)
  default     = {}
}