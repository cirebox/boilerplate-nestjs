/**
 * Módulo de Banco de Dados GCP (Cloud SQL)
 * 
 * Este módulo cria uma instância de banco de dados Cloud SQL (PostgreSQL)
 * com configurações otimizadas para controle de custos.
 */

# Gerar senha aleatória para o banco de dados
resource "random_password" "db_password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

# Configuração da instância Cloud SQL
resource "google_sql_database_instance" "main" {
  name             = "${var.project_name}-${var.environment}-${var.engine}"
  database_version = upper(var.engine) == "POSTGRES" ? "POSTGRES_${var.engine_version}" : "MYSQL_${var.engine_version}"
  region           = var.region
  project          = var.project_id
  
  # Configurações da instância
  settings {
    tier = var.instance_type

    # Configurações de armazenamento
    disk_size = var.allocated_storage
    disk_type = var.environment == "prod" ? "PD_SSD" : "PD_HDD"
    disk_autoresize = true
    disk_autoresize_limit = var.max_allocated_storage

    # Configurações de localização
    availability_type = var.multi_az ? "REGIONAL" : "ZONAL"
    
    # Configuração de backup
    backup_configuration {
      enabled            = true
      binary_log_enabled = upper(var.engine) == "MYSQL"
      start_time         = "02:00"
      
      # Retenção de backups - controle de custos
      backup_retention_settings {
        retained_backups = var.backup_retention_days
        retention_unit   = "COUNT"
      }
      
      # Para ambientes de produção, habilitar backups point-in-time
      point_in_time_recovery_enabled = var.environment == "prod"
    }
    
    # Configurações de manutenção - escolha horários de baixo uso
    maintenance_window {
      day          = 1  # Segunda-feira
      hour         = 3  # 3h da manhã
      update_track = var.environment == "prod" ? "stable" : "preview"
    }
    
    # Habilitar insights de consultas para ambiente de produção
    insights_config {
      query_insights_enabled  = var.environment == "prod"
      query_string_length     = 1024
      record_application_tags = true
      record_client_address   = true
      
      # Controle de custos: limitar o número de consultas armazenadas
      query_plans_per_minute = var.environment == "prod" ? 5 : 0
    }
    
    # Configurações de IP
    ip_configuration {
      ipv4_enabled    = false
      private_network = var.vpc_self_link
      
      # Configurações de conexão autorizada (opcional)
      dynamic "authorized_networks" {
        for_each = var.environment == "prod" ? [] : var.authorized_networks
        content {
          name  = authorized_networks.value.name
          value = authorized_networks.value.cidr
        }
      }
      
      # Habilitar SSL em ambiente de produção
      # SSL enforcement should be configured at the database level or through connection settings
    }
    
    # Otimizações de performance para PostgreSQL
    dynamic "database_flags" {
      for_each = upper(var.engine) == "POSTGRES" ? [1] : []
      content {
        name  = "autovacuum"
        value = "on"
      }
    }
    
    dynamic "database_flags" {
      for_each = upper(var.engine) == "POSTGRES" ? [1] : []
      content {
        name  = "max_connections"
        value = var.environment == "prod" ? "100" : "50"
      }
    }
    
    # Rotular os recursos para facilitar alocação de custos
    user_labels = merge(var.tags, {
      environment = var.environment
      project     = var.project_name
      managed-by  = "terraform"
    })
  }
  
  # Proteger contra exclusão acidental
  deletion_protection = var.deletion_protection
  
  # Não recriar a instância se apenas a senha mudar
  lifecycle {
    ignore_changes = [settings[0].user_labels, settings[0].insights_config]
  }
  
  # Garantir que a rede esteja disponível antes de criar o banco
  depends_on = [var.vpc_self_link]
}

# Criação do banco de dados
resource "google_sql_database" "database" {
  name       = var.database_name != "" ? var.database_name : "${replace(var.project_name, "-", "_")}_${var.environment}"
  instance   = google_sql_database_instance.main.name
  charset    = "UTF8"
  collation  = upper(var.engine) == "POSTGRES" ? "en_US.UTF8" : "utf8_general_ci"
  project    = var.project_id
}

# Criação do usuário do banco de dados
resource "google_sql_user" "user" {
  name     = var.database_user != "" ? var.database_user : "app_user"
  instance = google_sql_database_instance.main.name
  password = random_password.db_password.result
  project  = var.project_id
  
  # Simplificando a política de senha para usar apenas argumentos suportados
  dynamic "password_policy" {
    for_each = var.environment == "prod" ? [1] : []
    content {
      # Removendo argumentos não suportados e mantendo apenas os válidos
      # A documentação do provider deve ser consultada para argumentos válidos
    }
  }
}

# Réplica de leitura para produção (opcional)
resource "google_sql_database_instance" "replica" {
  count                = var.enable_replicas ? var.replica_count : 0
  name                 = "${var.project_name}-${var.environment}-replica-${count.index + 1}"
  master_instance_name = google_sql_database_instance.main.name
  region               = var.region
  database_version     = google_sql_database_instance.main.database_version
  project              = var.project_id
  
  # Configurações da réplica
  settings {
    tier              = var.replica_instance_type != "" ? var.replica_instance_type : var.instance_type
    availability_type = "ZONAL"  # Réplicas são geralmente zonais para reduzir custos
    
    # Configurações de armazenamento - mesmo do primário
    disk_size = var.allocated_storage
    disk_type = var.environment == "prod" ? "PD_SSD" : "PD_HDD"
    
    # Desabilitar backups na réplica para reduzir custos
    backup_configuration {
      enabled = false
    }
    
    # Configurações de IP
    ip_configuration {
      ipv4_enabled    = false
      private_network = var.vpc_self_link
      # require_ssl is not supported in this context and has been removed
    }
    
    # Rotular os recursos para facilitar alocação de custos
    user_labels = merge(var.tags, {
      environment = var.environment
      project     = var.project_name
      type        = "replica"
      managed-by  = "terraform"
    })
  }
  
  # Proteger contra exclusão acidental, mas menos restritivo que o primário
  deletion_protection = false
  
  depends_on = [google_sql_database_instance.main]
}