output "db_connection_string" {
  description = "Connection string para o banco de dados local"
  value       = "postgresql://${var.db_username}:${var.db_password}@localhost:${var.db_port}/${var.db_name}"
  sensitive   = true
}

output "app_url" {
  description = "URL da aplicação local"
  value       = var.deploy_app ? "http://localhost:${var.app_port}" : null
}

output "database_container_id" {
  description = "ID do container do banco de dados"
  value       = docker_container.database.id
}

output "database_container_name" {
  description = "Nome do container do banco de dados"
  value       = docker_container.database.name
}

output "app_container_id" {
  description = "ID do container da aplicação"
  value       = var.deploy_app ? docker_container.app[0].id : null
}

output "app_container_name" {
  description = "Nome do container da aplicação"
  value       = var.deploy_app ? docker_container.app[0].name : null
}

output "network_id" {
  description = "ID da rede Docker"
  value       = docker_network.local_network.id
}

output "network_name" {
  description = "Nome da rede Docker"
  value       = docker_network.local_network.name
}

output "volume_name" {
  description = "Nome do volume Docker para dados do banco"
  value       = docker_volume.local_data.name
}

