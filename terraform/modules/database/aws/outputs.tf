output "endpoint" {
  description = "Endpoint de conexão do banco de dados"
  value       = aws_db_instance.default.endpoint
}

output "address" {
  description = "Endereço do banco de dados"
  value       = aws_db_instance.default.address
}

output "port" {
  description = "Porta do banco de dados"
  value       = aws_db_instance.default.port
}

output "name" {
  description = "Nome do banco de dados"
  value       = aws_db_instance.default.db_name
}

output "username" {
  description = "Nome de usuário do banco de dados"
  value       = aws_db_instance.default.username
}

output "password" {
  description = "Senha do banco de dados"
  value       = random_password.db_password.result
  sensitive   = true
}

output "replica_endpoints" {
  description = "Lista de endpoints das réplicas de leitura"
  value       = var.enable_replicas ? aws_db_instance.read_replica[*].endpoint : []
}

output "connection_string" {
  description = "String de conexão do banco de dados"
  value       = "postgresql://${aws_db_instance.default.username}:${random_password.db_password.result}@${aws_db_instance.default.address}:${aws_db_instance.default.port}/${aws_db_instance.default.db_name}"
  sensitive   = true
}

output "secret_arn" {
  description = "ARN do segredo que contém as credenciais do banco de dados"
  value       = aws_secretsmanager_secret.db_credentials.arn
}

output "estimated_monthly_cost" {
  description = "Custo mensal estimado do banco de dados"
  value = {
    main_instance = {
      type = var.instance_type
      cost = var.instance_type == "db.t3.micro" ? "15-25 USD/mês" : (
        var.instance_type == "db.t3.small" ? "30-40 USD/mês" : (
        var.instance_type == "db.t3.medium" ? "60-80 USD/mês" : "Verificar calculadora AWS")
      )
    }
    replicas = var.enable_replicas ? {
      count = var.replica_count
      type  = var.replica_instance_type != "" ? var.replica_instance_type : var.instance_type
      cost = (var.replica_instance_type != "" ? var.replica_instance_type : var.instance_type) == "db.t3.micro" ? "15-25 USD/mês por réplica" : (
        (var.replica_instance_type != "" ? var.replica_instance_type : var.instance_type) == "db.t3.small" ? "30-40 USD/mês por réplica" : (
        (var.replica_instance_type != "" ? var.replica_instance_type : var.instance_type) == "db.t3.medium" ? "60-80 USD/mês por réplica" : "Verificar calculadora AWS")
      )
    } : null
    storage = {
      initial_gb  = var.allocated_storage
      cost_per_gb = "0.115-0.23 USD/GB/mês (dependendo da região)"
    }
    backup = {
      retention_days = var.backup_retention_days
      cost           = "Grátis para até 100% do tamanho do banco. Valores adicionais: 0.095 USD/GB/mês"
    }
  }
}

output "optimization_tips" {
  description = "Dicas para otimização de custos do banco de dados"
  value = [
    "Use instâncias reservadas para obter descontos de até 60% para cargas de trabalho previsíveis",
    "Considere Aurora Serverless para cargas de trabalho variáveis ou intermitentes",
    "Configure o auto-scaling do armazenamento para evitar provisionamento excessivo",
    "Para ambientes de desenvolvimento, desligue os bancos de dados quando não estiverem em uso",
    "Monitore o uso para identificar oportunidades de downsizing"
  ]
}