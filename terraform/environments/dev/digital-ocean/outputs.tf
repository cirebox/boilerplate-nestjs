output "vpc_id" {
  description = "ID da VPC criada"
  value       = module.network.vpc_id
}

output "vpc_name" {
  description = "Nome da VPC criada"
  value       = module.network.vpc_name
}

output "project_id" {
  description = "ID do projeto Digital Ocean"
  value       = module.network.project_id
}

output "database_connection_string" {
  description = "String de conexão para o banco de dados"
  value       = module.database.connection_string
  sensitive   = true
}

output "database_cluster_name" {
  description = "Nome do cluster de banco de dados"
  value       = module.database.database_cluster_name
}

output "database_user" {
  description = "Usuário do banco de dados"
  value       = module.database.database_user
}

output "database_private_uri" {
  description = "URI privada do banco de dados (para acesso pela VPC)"
  value       = module.database.private_uri
  sensitive   = true
}

output "kubernetes_cluster_id" {
  description = "ID do cluster Kubernetes"
  value       = module.kubernetes.cluster_id
}

output "kubernetes_cluster_name" {
  description = "Nome do cluster Kubernetes"
  value       = module.kubernetes.cluster_name
}

output "kubernetes_endpoint" {
  description = "Endpoint da API do Kubernetes"
  value       = module.kubernetes.endpoint
}

output "kubectl_config_command" {
  description = "Comando para configurar o kubectl local"
  value       = module.kubernetes.kubectl_config_command
}

output "monthly_cost_estimate" {
  description = "Estimativa mensal de custos (em USD)"
  value = {
    network    = "~$0 (VPC não tem custo adicional)"
    database   = module.database.estimated_monthly_cost.instance_type.cost_estimate
    kubernetes = module.kubernetes.estimated_monthly_cost.node_pool_default.monthly_estimate
    total_estimate = "${
      tonumber(regex("\\d+", module.database.estimated_monthly_cost.instance_type.cost_estimate)) +
      module.kubernetes.estimated_monthly_cost.node_pool_default.monthly_estimate
    }/mês (aproximado)"
  }
}

output "cost_saving_tips" {
  description = "Dicas para economizar custos no ambiente de desenvolvimento"
  value = concat(
    module.cost_monitor.cost_saving_recommendations,
    [
      "11. Considere desligar o cluster Kubernetes em períodos sem desenvolvimento ativo",
      "12. Para economia máxima, destrua a infraestrutura quando não estiver em uso e recrie quando necessário"
    ]
  )
}