output "daily_spend_alert_id" {
  description = "ID do alerta de gastos diários"
  value       = digitalocean_monitor_alert.balance_low.id
}

output "monthly_spend_alert_id" {
  description = "ID do alerta de gastos mensais"
  value       = digitalocean_monitor_alert.monthly_spend.id
}

output "waste_detection_enabled" {
  description = "Status da detecção de desperdício de recursos"
  value       = var.enable_waste_detection
}

output "waste_detection_alerts" {
  description = "IDs dos alertas de detecção de desperdício (se habilitados)"
  value       = var.enable_waste_detection ? {
    idle_droplet_alert    = digitalocean_monitor_alert.idle_droplet[0].id
    unused_volume_alert   = digitalocean_monitor_alert.volume_underused[0].id
    floating_ip_alert     = digitalocean_monitor_alert.floating_ip_unused[0].id
  } : null
}

output "notification_channels" {
  description = "Canais de notificação configurados"
  value       = {
    email = var.alert_emails
    slack = var.slack_channel != "" ? {
      channel = var.slack_channel
      webhook_configured = var.slack_webhook_url != ""
    } : null
  }
}

output "cost_monitoring_summary" {
  description = "Resumo da configuração de monitoramento de custos"
  value = {
    daily_threshold  = "$${var.budget_threshold}"
    monthly_limit    = "$${var.monthly_budget_limit}"
    waste_detection  = var.enable_waste_detection ? "Habilitado" : "Desabilitado"
    alerting_via     = concat(
      ["Email (${join(", ", var.alert_emails)})"],
      var.slack_channel != "" ? ["Slack (${var.slack_channel})"] : []
    )
  }
}

output "cost_saving_recommendations" {
  description = "Recomendações para controle de custos no Digital Ocean"
  value = [
    "1. Redimensione Droplets subutilizados para tamanhos menores",
    "2. Utilize volumes de armazenamento adequados às suas necessidades reais",
    "3. Desligue ambientes de desenvolvimento em períodos inativos",
    "4. Revise snapshots e backups antigos e desnecessários",
    "5. Utilize volumes com backup apenas quando necessário",
    "6. Consolide recursos em menos Droplets quando possível",
    "7. Use o modo 'hibernation' para Droplets que não precisam estar sempre disponíveis",
    "8. Revise balanceadores de carga e considere alternativas para ambientes não críticos",
    "9. Monitore transferência de dados e otimize para reduzir custos",
    "10. Utilize reserved instances para workloads estáveis e de longa duração"
  ]
}