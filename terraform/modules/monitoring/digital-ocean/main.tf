terraform {
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.36"
    }
  }
}

# Configuração para uso de alerta com Uptime Checks
resource "digitalocean_uptime_alert" "high_cpu" {
  name        = "${var.environment}-${var.project_name}-high-cpu"
  type        = "latency"  # Corrigido para um tipo válido
  check_id    = digitalocean_uptime_check.service_check.id
  threshold   = 300 # ms
  period      = "2m"
  comparison  = "greater_than"
  notifications {
    email = var.notification_emails
  }
}

# Uptime Check para o serviço principal
resource "digitalocean_uptime_check" "service_check" {
  name     = "${var.environment}-${var.project_name}-service-health"
  target   = var.service_endpoint
  type     = "http"
  enabled  = true
  regions  = ["us", "eu"]
}

# Monitor alerts para CPU e memória do cluster Kubernetes

# Obtém dados do cluster Kubernetes para referência nos alerts
data "digitalocean_kubernetes_cluster" "cluster" {
  name = var.cluster_name
}

# Alerta para alta utilização de CPU no cluster
resource "digitalocean_monitor_alert" "cpu_alert" {
  description = "Alerta para alta utilização de CPU no cluster ${var.cluster_name}"
  type        = "v1/insights/droplet/cpu"
  compare     = "GreaterThan"
  value       = var.cpu_threshold
  window      = "5m"
  entities    = [data.digitalocean_kubernetes_cluster.cluster.node_pool[0].nodes[*].droplet_id]
  
  alerts {
    email = var.notification_emails
    slack {
      channel = var.slack_channel
      url     = var.slack_webhook_url
    }
  }
  
  tags = toset([
    "environment:${var.environment}",
    "project:${var.project_name}"
  ])
}

# Alerta para alta utilização de memória no cluster
resource "digitalocean_monitor_alert" "memory_alert" {
  description = "Alerta para alta utilização de memória no cluster ${var.cluster_name}"
  type        = "v1/insights/droplet/memory_utilization_percent"
  compare     = "GreaterThan"
  value       = var.memory_threshold
  window      = "5m"
  entities    = [data.digitalocean_kubernetes_cluster.cluster.node_pool[0].nodes[*].droplet_id]
  
  alerts {
    email = var.notification_emails
    slack {
      channel = var.slack_channel
      url     = var.slack_webhook_url
    }
  }
  
  tags = toset([
    "environment:${var.environment}",
    "project:${var.project_name}"
  ])
}

# Alerta para disco cheio nos nós do cluster
resource "digitalocean_monitor_alert" "disk_alert" {
  description = "Alerta para alta utilização de disco no cluster ${var.cluster_name}"
  type        = "v1/insights/droplet/disk_utilization_percent"
  compare     = "GreaterThan"
  value       = var.disk_threshold # Precisamos adicionar esta variável
  window      = "5m"
  entities    = [data.digitalocean_kubernetes_cluster.cluster.node_pool[0].nodes[*].droplet_id]
  
  alerts {
    email = var.notification_emails
    slack {
      channel = var.slack_channel
      url     = var.slack_webhook_url
    }
  }
  
  tags = toset([
    "environment:${var.environment}",
    "project:${var.project_name}"
  ])
}

# Alerta para falhas no healthcheck do serviço
resource "digitalocean_monitor_alert" "healthcheck_alert" {
  count       = var.service_endpoint != "" ? 1 : 0
  description = "Alerta para falhas no healthcheck do serviço ${var.project_name}"
  type        = "v1/insights/droplet/load_5"
  compare     = "GreaterThan"
  value       = 1.5
  window      = "5m"
  entities    = [data.digitalocean_kubernetes_cluster.cluster.node_pool[0].nodes[*].droplet_id]
  
  alerts {
    email = var.notification_emails
    slack {
      channel = var.slack_channel
      url     = var.slack_webhook_url
    }
  }
  
  tags = toset([
    "environment:${var.environment}",
    "project:${var.project_name}",
    "monitor:healthcheck"
  ])
}
