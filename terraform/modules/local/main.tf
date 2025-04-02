# Este módulo cria um ambiente de desenvolvimento local usando Docker

# Removida a configuração local de providers para permitir uso com count/for_each
# terraform {
#   required_providers {
#     docker = {
#       source  = "kreuzwerker/docker"
#       version = "~> 3.0"
#     }
#   }
# }

# Removido o provider interno
# provider "docker" {
#   host = var.docker_host
# }

resource "docker_network" "local_network" {
  count = var.enabled ? 1 : 0
  name  = var.network_name
}

resource "docker_volume" "local_data" {
  count = var.enabled ? 1 : 0
  name  = var.data_volume_name
}

resource "docker_container" "database" {
  count = var.enabled ? 1 : 0
  name  = "${var.project_name}-db"
  image = var.database_image
  restart = "unless-stopped"
  
  networks_advanced {
    name = docker_network.local_network[0].name
  }
  
  volumes {
    volume_name    = docker_volume.local_data[0].name
    container_path = "/var/lib/postgresql/data"
  }
  
  env = [
    "POSTGRES_PASSWORD=${var.db_password}",
    "POSTGRES_USER=${var.db_username}",
    "POSTGRES_DB=${var.db_name}"
  ]
  
  ports {
    internal = 5432
    external = var.db_port
  }
}

resource "docker_container" "app" {
  count = var.enabled && var.deploy_app ? 1 : 0
  name  = "${var.project_name}-app"
  image = var.app_image
  restart = "unless-stopped"
  
  networks_advanced {
    name = docker_network.local_network[0].name
  }
  
  ports {
    internal = 3000
    external = var.app_port
  }
  
  env = [
    "DATABASE_HOST=${docker_container.database[0].name}",
    "DATABASE_PORT=5432",
    "DATABASE_USERNAME=${var.db_username}",
    "DATABASE_PASSWORD=${var.db_password}",
    "DATABASE_NAME=${var.db_name}",
    "NODE_ENV=development"
  ]
  
  depends_on = [docker_container.database]
}

