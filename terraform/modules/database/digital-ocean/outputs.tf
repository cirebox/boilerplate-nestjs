output "database_cluster_id" {
  description = "ID do cluster de banco de dados"
  value       = digitalocean_database_cluster.main.id
}

output "database_cluster_name" {
  description = "Nome do cluster de banco de dados"
  value       = digitalocean_database_cluster.main.name
}

output "database_name" {
  description = "Nome do banco de dados criado"
  value       = digitalocean_database_db.database.name
}

output "database_user" {
  description = "Nome de usuário para o banco de dados"
  value       = digitalocean_database_user.user.name
}

output "database_password" {
  description = "Senha do banco de dados"
  value       = digitalocean_database_user.user.password
  sensitive   = true
}

output "host" {
  description = "Host do banco de dados"
  value       = digitalocean_database_cluster.main.host
}

output "port" {
  description = "Porta do banco de dados"
  value       = digitalocean_database_cluster.main.port
}

output "private_host" {
  description = "Host privado do banco de dados (para acesso via VPC)"
  value       = digitalocean_database_cluster.main.private_host
}

output "uri" {
  description = "URI de conexão para o banco de dados"
  value       = digitalocean_database_cluster.main.uri
  sensitive   = true
}

output "private_uri" {
  description = "URI privada de conexão para o banco de dados (para acesso via VPC)"
  value       = digitalocean_database_cluster.main.private_uri
  sensitive   = true
}

output "connection_pool_uri" {
  description = "URI de conexão do pool (apenas para ambiente de produção)"
  value       = var.environment == "prod" ? digitalocean_database_connection_pool.pool[0].uri : null
  sensitive   = true
}

output "connection_string" {
  description = "String de conexão formatada para o banco de dados"
  value       = var.engine == "pg" ? "postgresql://${digitalocean_database_user.user.name}:${digitalocean_database_user.user.password}@${digitalocean_database_cluster.main.private_host}:${digitalocean_database_cluster.main.port}/${digitalocean_database_db.database.name}" : null
  sensitive   = true
}

output "endpoint" {
  description = "Endpoint para acessar o banco de dados (formato compatível com outros provedores)"
  value       = "${digitalocean_database_cluster.main.private_host}:${digitalocean_database_cluster.main.port}"
}

# Cálculos de custo usando locals
locals {
  db_instance_costs = {
    "db-s-1vcpu-1gb"  = 15
    "db-s-1vcpu-2gb"  = 25
    "db-s-2vcpu-4gb"  = 60
    "db-s-4vcpu-8gb"  = 120
    "db-s-6vcpu-16gb" = 235
    "db-s-8vcpu-32gb" = 470
    "default"         = 25
  }
  
  # Cálculos de custo do ambiente de produção e desenvolvimento
  prod_cost = lookup(local.db_instance_costs, var.instance_type, local.db_instance_costs["default"]) * var.node_count
  dev_cost = lookup(local.db_instance_costs, var.instance_type, local.db_instance_costs["default"])
}

output "estimated_monthly_cost" {
  description = "Estimativa de custos mensais do banco de dados"
  value = {
    instance_type = {
      size = var.instance_type
      cost_estimate = var.instance_type == "db-s-1vcpu-1gb" ? "15 USD/mês" : (
                     var.instance_type == "db-s-1vcpu-2gb" ? "25 USD/mês" : (
                     var.instance_type == "db-s-2vcpu-4gb" ? "60 USD/mês" : (
                     var.instance_type == "db-s-4vcpu-8gb" ? "120 USD/mês" : (
                     var.instance_type == "db-s-6vcpu-16gb" ? "235 USD/mês" : (
                     var.instance_type == "db-s-8vcpu-32gb" ? "470 USD/mês" : "Verificar preços DigitalOcean")))))
    }
    node_count = {
      count = var.environment == "prod" ? var.node_count : 1
      total_cost = var.environment == "prod" ? "${local.prod_cost} USD/mês" : "${local.dev_cost} USD/mês"
    }
    storage = "Incluído no preço do plano"
    backup = "Incluído no preço do plano (7 dias de backup)"
    savings_tips = [
      "Use o menor tamanho de instância que atenda às necessidades",
      "Evite clusters em produção para ambientes de desenvolvimento",
      "Considere usar um banco de dados compartilhado para vários projetos em dev/staging"
    ]
  }
}

output "optimization_tips" {
  description = "Dicas para otimização de custos do banco de dados"
  value = [
    "Escolha o tamanho correto da instância para suas necessidades",
    "Use o menor número de nós possível para ambientes não críticos",
    "Aproveite as características de alta disponibilidade incluídas",
    "Monitore o uso para evitar sobreprovisionamento",
    "Consolide bancos de dados de desenvolvimento em uma única instância"
  ]
}