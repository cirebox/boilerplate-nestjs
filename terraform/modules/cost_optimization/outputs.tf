# Arquivo de saídas do módulo de otimização de custos
# Define todas as informações que podem ser úteis para o módulo principal

output "estimated_monthly_savings" {
  description = "Economia mensal estimada em USD com base nas otimizações implementadas"
  value       = var.enable_cost_optimization ? local.estimated_savings : 0
  sensitive   = false
}

output "underutilized_resources" {
  description = "Lista de recursos identificados como subutilizados"
  value       = var.enable_resource_monitoring ? local.underutilized_resources : []
}

output "scheduled_shutdowns" {
  description = "Detalhes dos recursos programados para desligamento automático"
  value = var.enable_auto_shutdown ? {
    resources          = local.resources_for_shutdown
    shutdown_schedule  = var.shutdown_schedule
    startup_schedule   = var.startup_schedule
    timezone           = var.schedule_timezone
    excluded_resources = var.shutdown_exclusions
  } : null
}

output "cost_dashboard_url" {
  description = "URL para o dashboard de monitoramento de custos"
  value       = var.enable_cost_dashboard ? local.dashboard_url : ""
}

output "budget_alerts" {
  description = "Configurações de alertas de orçamento"
  value = var.enable_budget_alerts ? {
    threshold_percentage = var.budget_alert_threshold
    contacts             = var.budget_alert_contacts
    monthly_budget       = var.monthly_budget
  } : null
}

output "resource_tags" {
  description = "Tags aplicadas aos recursos para monitoramento de custos"
  value       = local.cost_tags
}

output "optimization_recommendations" {
  description = "Lista de recomendações de otimização de custos"
  value       = var.enable_recommendations ? local.optimization_recommendations : []
}

output "inactive_resources" {
  description = "Recursos inativos que podem ser removidos"
  value       = var.enable_resource_cleanup ? local.inactive_resources : []
  sensitive   = false
}

output "cost_anomaly_detection_enabled" {
  description = "Indica se a detecção de anomalias de custo está ativada"
  value       = var.enable_cost_anomaly_detection
}

output "monitoring_period" {
  description = "Período em dias usado para análise de uso de recursos"
  value       = var.resource_analysis_period_days
}

