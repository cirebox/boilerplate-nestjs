variable "enabled" {
  description = "Flag para ativar ou desativar a criação de recursos deste módulo"
  type        = bool
  default     = true
}

variable "project_name" {
  description = "Nome do projeto"
  type        = string
}

variable "docker_host" {
  description = "The Docker host to connect to"
  type        = string
  default     = "unix:///var/run/docker.sock"
}

variable "network_name" {
  description = "Name of the Docker network"
  type        = string
  default     = "nestjs-local-network"
}

variable "data_volume_name" {
  description = "Name of the Docker volume for database data"
  type        = string
  default     = "nestjs-db-data"
}

variable "database_image" {
  description = "Docker image for the database"
  type        = string
  default     = "postgres:14"
}

variable "app_image" {
  description = "Docker image for the application"
  type        = string
  default     = "node:18-alpine"
}

variable "db_username" {
  description = "Database username"
  type        = string
  default     = "postgres"
}

variable "db_password" {
  description = "Database password"
  type        = string
  default     = "postgres"
  sensitive   = true
}

variable "db_name" {
  description = "Database name"
  type        = string
  default     = "nestjs"
}

variable "db_port" {
  description = "External port for the database"
  type        = number
  default     = 5432
}

variable "app_port" {
  description = "External port for the application"
  type        = number
  default     = 3000
}

variable "deploy_app" {
  description = "Whether to deploy the application container"
  type        = bool
  default     = true
}

