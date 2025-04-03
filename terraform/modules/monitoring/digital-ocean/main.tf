# O bloco terraform com required_providers foi removido, pois agora as versões dos providers
# são gerenciadas centralmente no arquivo versions.tf na raiz do diretório terraform

# Configuração para uso de alerta com Uptime Checks
resource "digitalocean_uptime_alert" "high_cpu" {
  name       = "${var.environment}-${var.project_name}-high-cpu"
  type       = "latency" # Tipo válido: latency (tempo de resposta)
  check_id   = digitalocean_uptime_check.service_check.id
  threshold  = 300 # ms
  period     = "2m"
  comparison = "greater_than"
  notifications {
    email = var.notification_emails
  }
}

# Uptime Check para o serviço principal
resource "digitalocean_uptime_check" "service_check" {
  name    = "${var.environment}-${var.project_name}-service-health"
  target  = var.service_endpoint
  type    = "http"
  enabled = true
  regions = ["us", "eu"]
}

# Adicionando monitor alert para CPU (com tipo corrigido)
resource "digitalocean_monitor_alert" "cpu_alert" {
  count = var.cluster_name != "" ? 1 : 0
  alerts {
    email = var.notification_emails
    slack {
      channel = var.slack_channel
      url     = var.slack_webhook_url
    }
  }
  window      = "5m"
  type        = "v1/insights/droplet/cpu" # Tipo corrigido para monitoramento de CPU
  compare     = "GreaterThan"
  value       = var.cpu_threshold
  description = "Alerta para alta utilização de CPU no cluster ${var.cluster_name}"
  enabled     = true
}

# Adicionando monitor alert para memória
resource "digitalocean_monitor_alert" "memory_alert" {
  count = var.cluster_name != "" ? 1 : 0
  alerts {
    email = var.notification_emails
    slack {
      channel = var.slack_channel
      url     = var.slack_webhook_url
    }
  }
  window      = "5m"
  type        = "v1/insights/droplet/memory_utilization_percent" # Tipo correto para memória
  compare     = "GreaterThan"
  value       = var.memory_threshold
  description = "Alerta para alta utilização de memória no cluster ${var.cluster_name}"
  enabled     = true
}
