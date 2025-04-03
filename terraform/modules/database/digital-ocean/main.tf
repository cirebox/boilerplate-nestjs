# Módulo de banco de dados gerenciado para Digital Ocean
# Este módulo implementa um cluster Postgres gerenciado na Digital Ocean

# O bloco terraform com required_providers foi removido, pois agora as versões dos providers
# são gerenciadas centralmente no arquivo versions.tf na raiz do diretório terraform

# Gerar senha aleatória para o banco de dados
resource "random_password" "db_password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

# Cluster de banco de dados
resource "digitalocean_database_cluster" "main" {
  name                 = "${var.project_name}-${var.environment}-db"
  engine               = var.engine
  version              = var.engine_version
  size                 = var.instance_type
  region               = var.region
  node_count           = var.environment == "prod" ? var.node_count : 1
  private_network_uuid = var.vpc_id

  # Removendo a configuração de backup_restore que contém atributos não suportados

  # Configurações de manutenção - definir para horários de baixo tráfego
  maintenance_window {
    day  = "sunday"
    hour = "02:00:00"
  }

  # Configurações de proteção contra exclusão acidental
  lifecycle {
    prevent_destroy = false # Altere para true em produção
  }
}

# Banco de dados específico dentro do cluster
resource "digitalocean_database_db" "database" {
  cluster_id = digitalocean_database_cluster.main.id
  name       = var.database_name != "" ? var.database_name : "${replace(var.project_name, "-", "_")}_${var.environment}"
}

# Usuário para o banco de dados
resource "digitalocean_database_user" "user" {
  cluster_id        = digitalocean_database_cluster.main.id
  name              = var.database_user != "" ? var.database_user : "app_user"
  mysql_auth_plugin = var.engine == "mysql" ? "mysql_native_password" : null
}

# Conexão com um projeto Digital Ocean para facilitar gerenciamento
resource "digitalocean_database_firewall" "database_fw" {
  cluster_id = digitalocean_database_cluster.main.id

  # Permitir acesso apenas da própria VPC para segurança
  rule {
    type  = "ip_addr"
    value = var.vpc_cidr
  }

  # Opcionalmente permitir acesso de outros IPs para facilitar desenvolvimento
  dynamic "rule" {
    for_each = var.environment != "prod" ? var.allowed_ips : []
    content {
      type  = "ip_addr"
      value = rule.value
    }
  }
}

# Configuração do pool de conexão (opcional, apenas para produção)
resource "digitalocean_database_connection_pool" "pool" {
  count      = var.environment == "prod" ? 1 : 0
  cluster_id = digitalocean_database_cluster.main.id
  name       = "${var.project_name}-${var.environment}-pool"
  mode       = "transaction"
  size       = 10
  db_name    = digitalocean_database_db.database.name
  user       = digitalocean_database_user.user.name
}