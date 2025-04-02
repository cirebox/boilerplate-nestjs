# Variáveis para o módulo de snapshots de recuperação de desastres

variable "environment" {
  description = "Ambiente para o qual os snapshots serão configurados (dev, staging, prod)"
  type        = string
}

variable "project_name" {
  description = "Nome do projeto para identificação dos snapshots"
  type        = string
}

variable "do_token" {
  description = "Token da API da Digital Ocean para acesso aos recursos"
  type        = string
  sensitive   = true
}

variable "region" {
  description = "Região onde os recursos estão localizados"
  type        = string
  default     = "nyc1"
}

# Configurações para snapshots de banco de dados
variable "enable_db_snapshots" {
  description = "Ativar a criação de snapshots de banco de dados"
  type        = bool
  default     = true
}

variable "database_cluster_id" {
  description = "ID do cluster de banco de dados para backup"
  type        = string
  default     = ""
}

variable "backup_server_ip" {
  description = "Endereço IP do servidor de backup que terá acesso ao banco de dados"
  type        = string
  default     = ""
}

# Configurações para snapshots de volumes
variable "enable_volume_snapshots" {
  description = "Ativar a criação de snapshots de volumes"
  type        = bool
  default     = true
}

variable "volumes_to_snapshot" {
  description = "Mapa de volumes para os quais serão criados snapshots"
  type = map(object({
    id   = string
    tags = map(string)
  }))
  default = {}
}

# Configurações para backups do Kubernetes
variable "enable_k8s_config_backups" {
  description = "Ativar backup das configurações do Kubernetes"
  type        = bool
  default     = true
}

variable "backup_bucket_name" {
  description = "Nome do bucket S3/Spaces onde os backups do Kubernetes serão armazenados"
  type        = string
  default     = ""
}

variable "spaces_access_key" {
  description = "Chave de acesso para o Spaces (compatível com S3)"
  type        = string
  sensitive   = true
  default     = ""
}

variable "spaces_secret_key" {
  description = "Chave secreta para o Spaces (compatível com S3)"
  type        = string
  sensitive   = true
  default     = ""
}

variable "k8s_backup_cron_schedule" {
  description = "Cronograma de backup para o Kubernetes no formato cron (padrão: diário às 2h da manhã)"
  type        = string
  default     = "0 2 * * *"
}

# Configurações de retenção e alertas
variable "retention_days" {
  description = "Número de dias para reter os snapshots"
  type        = number
  default     = 30
}

variable "alert_webhook_url" {
  description = "URL de webhook para enviar alertas (Slack, Discord, etc.)"
  type        = string
  default     = ""
}

