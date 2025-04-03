# Este módulo cria um ambiente de desenvolvimento local usando Docker

# O bloco terraform com required_providers foi removido, pois agora as versões dos providers
# são gerenciadas centralmente no arquivo versions.tf na raiz do diretório terraform

# Configuração da rede Docker local
resource "docker_network" "local_network" {
  count = var.enabled ? 1 : 0
  name  = var.network_name
}

# Volume persistente para o banco de dados
resource "docker_volume" "db_data" {
  count = var.enabled && var.create_database ? 1 : 0
  name  = "${var.project_name}-${var.environment}-db-data"
}

# Container de banco de dados PostgreSQL
resource "docker_container" "postgres" {
  count = var.enabled && var.create_database ? 1 : 0
  name  = "${var.project_name}-${var.environment}-db"
  image = "postgres:${var.postgres_version}"

  env = [
    "POSTGRES_PASSWORD=${var.postgres_password}",
    "POSTGRES_USER=${var.postgres_user}",
    "POSTGRES_DB=${var.postgres_db}"
  ]

  ports {
    internal = 5432
    external = var.postgres_port
    protocol = "tcp"
  }

  volumes {
    volume_name    = docker_volume.db_data[0].name
    container_path = "/var/lib/postgresql/data"
  }

  networks_advanced {
    name = docker_network.local_network[0].name
  }

  restart = "unless-stopped"
}

# Container da aplicação NestJS
resource "docker_container" "app" {
  count = var.enabled && var.create_app ? 1 : 0
  name  = "${var.project_name}-${var.environment}-app"
  image = var.app_image

  env = concat([
    "NODE_ENV=${var.environment}",
    "DATABASE_URL=postgresql://${var.postgres_user}:${var.postgres_password}@${docker_container.postgres[0].name}:5432/${var.postgres_db}",
    "PORT=${var.app_internal_port}"
  ], var.additional_environment_vars)

  ports {
    internal = var.app_internal_port
    external = var.app_external_port
    protocol = "tcp"
  }

  networks_advanced {
    name = docker_network.local_network[0].name
  }

  depends_on = [docker_container.postgres]
  restart    = "unless-stopped"
}

# Serviços adicionais (se habilitados)
resource "docker_container" "redis" {
  count = var.enabled && var.create_redis ? 1 : 0
  name  = "${var.project_name}-${var.environment}-redis"
  image = "redis:${var.redis_version}"

  ports {
    internal = 6379
    external = var.redis_port
    protocol = "tcp"
  }

  networks_advanced {
    name = docker_network.local_network[0].name
  }

  restart = "unless-stopped"
}

resource "docker_container" "pgadmin" {
  count = var.enabled && var.create_pgadmin ? 1 : 0
  name  = "${var.project_name}-${var.environment}-pgadmin"
  image = "dpage/pgadmin4:latest"

  env = [
    "PGADMIN_DEFAULT_EMAIL=${var.pgadmin_email}",
    "PGADMIN_DEFAULT_PASSWORD=${var.pgadmin_password}"
  ]

  ports {
    internal = 80
    external = var.pgadmin_port
    protocol = "tcp"
  }

  networks_advanced {
    name = docker_network.local_network[0].name
  }

  restart = "unless-stopped"
}

