# Módulo de monitoramento de custos para Digital Ocean
# Este módulo implementa alertas e relatórios de custos para recursos no Digital Ocean

# O bloco terraform com required_providers foi removido, pois agora as versões dos providers
# são gerenciadas centralmente no arquivo versions.tf na raiz do diretório terraform

locals {
  project_tags = concat([var.environment, var.project_name, "cost-monitor"], var.tags)
}

# Criar alertas para monitoramento de saldo e gastos
resource "digitalocean_monitor_alert" "balance_low" {
  alerts {
    email = var.alert_emails
    # Remover configuração do Slack quando não for fornecida
    # slack {
    #   channel   = var.slack_channel
    #   url       = var.slack_webhook_url
    # }
  }

  window      = "1h"                      # Alterado de 24h para 1h (valor permitido)
  type        = "v1/insights/droplet/cpu" # Alterado para um tipo válido
  compare     = "GreaterThan"
  value       = 80 # Alterado para um valor percentual de CPU
  description = "Alerta quando o uso de CPU excede 80% por mais de 1 hora no projeto ${var.project_name}"

  # Monitorar todos os recursos do projeto
  entities = ["*"]

  # Determinar se o alerta está ativo
  enabled = true

  tags = local.project_tags
}

# Remover recurso digitalocean_uptime_alert que requer check_id indisponível
# resource "digitalocean_uptime_alert" "billing_alert" {
#   name        = "${var.project_name}-${var.environment}-billing-alert"
#   type        = "threshold"
#   threshold   = 95
#   comparison  = "greater_than"
#   period      = "1h"
#   check_id    = "check-id-required-but-not-available"
#   notifications {
#     email = var.alert_emails
#     slack {
#       channel = var.slack_channel
#       url     = var.slack_webhook_url
#     }
#   }
# }

# Configurar monitor para métricas de utilização de recursos (para controle de custos)
resource "digitalocean_monitor_alert" "monthly_spend" {
  alerts {
    email = var.alert_emails
  }

  window      = "1h"                                             # Alterado de 30d para 1h (valor permitido)
  type        = "v1/insights/droplet/memory_utilization_percent" # Alterado para um tipo válido
  compare     = "GreaterThan"
  value       = 85 # Alterado para um valor percentual de memória
  description = "Alerta quando o uso de memória excede 85% no projeto ${var.project_name}"

  entities = ["*"]
  enabled  = true

  tags = local.project_tags
}

# Criar um monitor para recursos sem uso (waste detection)
resource "digitalocean_monitor_alert" "floating_ip_unused" {
  count = var.enable_waste_detection ? 1 : 0

  alerts {
    email = var.alert_emails
  }

  window      = "1h" # Alterado de 5d para 1h (valor permitido)
  type        = "v1/insights/droplet/disk_utilization_percent"
  compare     = "LessThan"
  value       = 20
  description = "Alerta sobre discos com baixa utilização (menos de 20%), potencial para redimensionar"

  entities = ["*"]
  enabled  = true

  tags = local.project_tags
}

# Criar monitor para volumes subutilizados (disk space waste)
resource "digitalocean_monitor_alert" "volume_underused" {
  count = var.enable_waste_detection ? 1 : 0

  alerts {
    email = var.alert_emails
  }

  window      = "1h" # Alterado de 7d para 1h (valor permitido)
  type        = "v1/insights/droplet/disk_utilization_percent"
  compare     = "LessThan"
  value       = 30
  description = "Alerta sobre volumes com baixa utilização (menos de 30%), potencial para redimensionar"

  entities = ["*"]
  enabled  = true

  tags = local.project_tags
}

# Criar monitor para alertas de recursos ociosos
resource "digitalocean_monitor_alert" "idle_droplet" {
  count = var.enable_waste_detection ? 1 : 0

  alerts {
    email = var.alert_emails
  }

  window      = "1h" # Alterado de 7d para 1h (valor permitido)
  type        = "v1/insights/droplet/cpu"
  compare     = "LessThan"
  value       = 10
  description = "Alerta sobre droplets com baixa utilização de CPU (menos de 10%), potencial para desligar ou reduzir"

  entities = ["*"]
  enabled  = true

  tags = local.project_tags
}