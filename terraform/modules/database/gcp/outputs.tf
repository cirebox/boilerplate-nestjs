output "instance_name" {
  description = "Nome da instância Cloud SQL criada"
  value       = google_sql_database_instance.main.name
}

output "instance_connection_name" {
  description = "Connection name para a instância Cloud SQL"
  value       = google_sql_database_instance.main.connection_name
}

output "instance_self_link" {
  description = "Self-link da instância Cloud SQL"
  value       = google_sql_database_instance.main.self_link
}

output "instance_ip_address" {
  description = "Endereço IP privado da instância Cloud SQL"
  value       = google_sql_database_instance.main.private_ip_address
}

output "database_name" {
  description = "Nome do banco de dados criado"
  value       = google_sql_database.database.name
}

output "username" {
  description = "Nome de usuário do banco de dados"
  value       = google_sql_user.user.name
}

output "password" {
  description = "Senha do banco de dados"
  value       = random_password.db_password.result
  sensitive   = true
}

output "replica_instance_names" {
  description = "Lista de nomes das instâncias de réplica"
  value       = var.enable_replicas ? google_sql_database_instance.replica[*].name : []
}

output "replica_connection_names" {
  description = "Lista de connection names das réplicas"
  value       = var.enable_replicas ? google_sql_database_instance.replica[*].connection_name : []
}

output "connection_string" {
  description = "String de conexão para o banco de dados PostgreSQL"
  value       = upper(var.engine) == "POSTGRES" ? "postgresql://${google_sql_user.user.name}:${random_password.db_password.result}@${google_sql_database_instance.main.private_ip_address}:5432/${google_sql_database.database.name}" : "mysql://${google_sql_user.user.name}:${random_password.db_password.result}@${google_sql_database_instance.main.private_ip_address}:3306/${google_sql_database.database.name}"
  sensitive   = true
}

output "endpoint" {
  description = "Endpoint para acessar o banco de dados (formato compatível com outros provedores)"
  value       = "${google_sql_database_instance.main.private_ip_address}:${upper(var.engine) == "POSTGRES" ? "5432" : "3306"}"
}

# Cálculos de custos com locals
locals {
  # Custos estimados para diferentes tipos de instância
  instance_costs = {
    "db-f1-micro"      = "8-12 USD/mês"
    "db-g1-small"      = "25-35 USD/mês"
    "db-n1-standard-1" = "60-90 USD/mês"
    "default"          = "Verificar calculadora GCP"
  }

  # Valores numéricos para cálculos
  storage_cost_prod_min = 0.17
  storage_cost_prod_max = 0.24
  storage_cost_dev_min  = 0.09
  storage_cost_dev_max  = 0.12

  # Cálculos de custos de armazenamento
  storage_cost_estimate_prod = "${var.allocated_storage * local.storage_cost_prod_min}-${var.allocated_storage * local.storage_cost_prod_max} USD/mês"
  storage_cost_estimate_dev  = "${var.allocated_storage * local.storage_cost_dev_min}-${var.allocated_storage * local.storage_cost_dev_max} USD/mês"
}

output "estimated_monthly_cost" {
  description = "Estimativa de custos mensais do banco de dados Cloud SQL"
  value = {
    instance_type = {
      type          = var.instance_type
      cost_estimate = lookup(local.instance_costs, var.instance_type, local.instance_costs["default"])
    }
    high_availability = {
      enabled         = var.multi_az
      additional_cost = var.multi_az ? "100% adicional (dobra o custo da instância)" : "Não habilitado"
    }
    storage = {
      type           = var.environment == "prod" ? "SSD" : "HDD"
      size_gb        = var.allocated_storage
      cost_per_gb    = var.environment == "prod" ? "0.17-0.24 USD/GB/mês" : "0.09-0.12 USD/GB/mês"
      total_estimate = var.environment == "prod" ? local.storage_cost_estimate_prod : local.storage_cost_estimate_dev
    }
    replicas = var.enable_replicas ? {
      count = var.replica_count
      type  = var.replica_instance_type != "" ? var.replica_instance_type : var.instance_type
      cost_per_replica = lookup(local.instance_costs,
        var.replica_instance_type != "" ? var.replica_instance_type : var.instance_type,
      local.instance_costs["default"])
    } : { enabled = false, message = "Não habilitado" } # Corrigido: retorna um objeto ao invés de string
    network_egress = "Custos adicionais para tráfego de saída: 0.10-0.20 USD/GB"
    backup = {
      retention_days = var.backup_retention_days
      cost           = "7 primeiros backups gratuitos, adicionais a 0.08 USD/GB/mês"
    }
    savings_tips = [
      "Use o tier db-f1-micro para ambiente de desenvolvimento",
      "Desative alta disponibilidade em ambiente não produtivo",
      "Use HDD em vez de SSD para ambientes não produtivos",
      "Considere parar a instância quando não estiver em uso"
    ]
  }
}

output "optimization_tips" {
  description = "Dicas para otimização de custos do banco de dados"
  value = [
    "Use instâncias menores para ambientes de desenvolvimento e testes",
    "Considere parar instâncias de desenvolvimento quando não estiverem em uso",
    "Desative a alta disponibilidade em ambientes não-produtivos",
    "Use discos HDD em vez de SSD para ambientes não-produtivos",
    "Configure alertas de uso para identificar picos de utilização e potencial necessidade de escalonamento"
  ]
}