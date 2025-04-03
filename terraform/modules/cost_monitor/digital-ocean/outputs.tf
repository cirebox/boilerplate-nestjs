output "estimated_monthly_cost" {
  description = "Estimativa de custos mensais da infraestrutura de rede"
  value = {
    vpc = "Gratuito - VPCs no Digital Ocean não têm custo"
    load_balancer = var.create_loadbalancer ? {
      type = var.environment == "prod" ? "lb-small" : "lb-nano"
      cost = var.environment == "prod" ? "$${var.cost_estimates.lb_small}/mês" : "$${var.cost_estimates.lb_nano}/mês"
      } : {
      type = "N/A"
      cost = "$0/mês"
    }
    kubernetes_cluster = var.environment == "prod" ? {
      type = "Cluster de produção"
      cost = "$${var.cost_estimates.kubernetes_prod_node * 3}/mês (estimativa para 3 nós)"
      } : var.environment == "staging" ? {
      type = "Cluster de homologação"
      cost = "$${var.cost_estimates.kubernetes_basic_node * 2}/mês (estimativa para 2 nós)"
      } : {
      type = "Cluster dev"
      cost = "$${var.cost_estimates.kubernetes_basic_node}/mês (estimativa para 1 nó)"
    }
    banco_dados = var.environment == "prod" ? {
      type = "Cluster HA"
      cost = "$${var.cost_estimates.droplet_cpu * 2}/mês (cluster com 2 nós)"
      } : {
      type = "Single node"
      cost = "$${var.cost_estimates.droplet_basic}/mês"
    }
    volumes = {
      type = "Block Storage"
      cost = "Aproximadamente $${var.cost_estimates.volume_gb}/GB por mês"
    }
  }
}

output "optimization_tips" {
  description = "Dicas para otimização de custos no Digital Ocean"
  value = [
    "Use Droplets sob demanda para workloads temporárias",
    "Configure auto-scaling para reduzir custos em períodos de baixa demanda",
    "Utilize block storage com reservas se suas necessidades forem previsíveis",
    "Monitore recursos subutilizados regularmente",
    "Considere managed databases para reduzir custos operacionais",
    var.environment == "dev" ? "Em ambiente de desenvolvimento, desligue recursos não utilizados durante períodos inativos" : "",
    var.environment == "staging" ? "Em ambiente de homologação, considere usar instâncias menores durante desenvolvimento" : "",
    var.environment == "prod" ? "Em produção, avalie a necessidade de recursos reservados para economia a longo prazo" : ""
  ]
}

output "monthly_budget_limit" {
  description = "Limite de orçamento mensal configurado"
  value       = var.monthly_budget_limit
}

output "daily_budget_threshold" {
  description = "Limite de alerta diário configurado"
  value       = var.budget_threshold
}

output "notification_emails" {
  description = "Emails configurados para receber alertas de orçamento"
  value       = var.alert_emails
  sensitive   = true
}