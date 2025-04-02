output "budget_name" {
  description = "Nome do orçamento criado"
  value       = google_billing_budget.budget.display_name
}

output "pubsub_topic" {
  description = "Tópico Pub/Sub para alertas de orçamento"
  value       = google_pubsub_topic.budget_alerts.name
}

output "pubsub_subscription" {
  description = "Assinatura Pub/Sub para alertas de orçamento"
  value       = google_pubsub_subscription.budget_alerts.name
}

output "dashboard_name" {
  description = "Nome do dashboard de custos (se criado)"
  value       = var.environment == "prod" ? google_monitoring_dashboard.cost_dashboard[0].dashboard_json : null
}

output "estimated_monthly_cost" {
  description = "Orçamento mensal configurado"
  value       = var.budget_amount
}

output "optimization_tips" {
  description = "Dicas para otimização de custos no GCP"
  value = [
    "1. Use Preemptible VMs para cargas de trabalho com tolerância a falhas (até 80% mais baratas)",
    "2. Considere Spot VMs para workloads batch que podem ser interrompidas",
    "3. Configure o Autoscaling para ajustar automaticamente recursos conforme a demanda",
    "4. Use tipos de máquinas E2 para melhor custo-benefício em cargas de trabalho gerais",
    "5. Desative instâncias de desenvolvimento em períodos de inatividade (noites/fins de semana)",
    "6. Implemente políticas de ciclo de vida para armazenamento no Cloud Storage",
    "7. Utilize reservas de instâncias para workloads estáveis e de longo prazo",
    "8. Use o BigQuery flat-rate pricing para grandes volumes de consultas previsíveis",
    "9. Configure alertas de uso anômalo de recursos com o Cloud Monitoring",
    "10. Use o Cloud Asset Inventory para identificar recursos não utilizados"
  ]
}