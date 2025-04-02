terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 4.0"
    }
  }
}

# Policy de notificação para alertas
resource "google_monitoring_notification_channel" "email" {
  count        = length(var.notification_emails)
  display_name = "Email Notification ${count.index}"
  type         = "email"
  labels = {
    email_address = var.notification_emails[count.index]
  }
}

# Alerta para CPU alta
resource "google_monitoring_alert_policy" "high_cpu" {
  display_name = "${var.environment}-${var.project_name}-high-cpu"
  combiner     = "OR"
  conditions {
    display_name = "High CPU utilization"
    condition_threshold {
      filter          = "resource.type = \"k8s_container\" AND resource.labels.cluster_name = \"${var.cluster_name}\" AND resource.labels.namespace_name = \"${var.namespace}\" AND metric.type = \"kubernetes.io/container/cpu/utilization\""
      duration        = "60s"
      comparison      = "COMPARISON_GT"
      threshold_value = var.cpu_threshold / 100
      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_MEAN"
      }
    }
  }

  notification_channels = google_monitoring_notification_channel.email[*].id

  documentation {
    content   = "CPU usage is above ${var.cpu_threshold}% for ${var.service_name} in ${var.environment} environment."
    mime_type = "text/markdown"
  }

  alert_strategy {
    auto_close = "604800s" # 7 dias
  }
}

# Alerta para Memória alta
resource "google_monitoring_alert_policy" "high_memory" {
  display_name = "${var.environment}-${var.project_name}-high-memory"
  combiner     = "OR"
  conditions {
    display_name = "High memory utilization"
    condition_threshold {
      filter          = "resource.type = \"k8s_container\" AND resource.labels.cluster_name = \"${var.cluster_name}\" AND resource.labels.namespace_name = \"${var.namespace}\" AND metric.type = \"kubernetes.io/container/memory/used_bytes\""
      duration        = "60s"
      comparison      = "COMPARISON_GT"
      threshold_value = var.memory_threshold / 100
      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_MEAN"
      }
    }
  }

  notification_channels = google_monitoring_notification_channel.email[*].id

  documentation {
    content   = "Memory usage is above ${var.memory_threshold}% for ${var.service_name} in ${var.environment} environment."
    mime_type = "text/markdown"
  }

  alert_strategy {
    auto_close = "604800s" # 7 dias
  }
}

# Dashboard com visão geral dos recursos
resource "google_monitoring_dashboard" "dashboard" {
  dashboard_json = jsonencode({
    displayName = "${var.environment}-${var.project_name}-dashboard"
    gridLayout = {
      widgets = [
        {
          title = "CPU Utilization"
          xyChart = {
            dataSets = [{
              timeSeriesQuery = {
                timeSeriesFilter = {
                  filter = "resource.type = \"k8s_container\" AND resource.labels.cluster_name = \"${var.cluster_name}\" AND resource.labels.namespace_name = \"${var.namespace}\" AND metric.type = \"kubernetes.io/container/cpu/utilization\""
                }
              }
            }]
          }
        },
        {
          title = "Memory Utilization"
          xyChart = {
            dataSets = [{
              timeSeriesQuery = {
                timeSeriesFilter = {
                  filter = "resource.type = \"k8s_container\" AND resource.labels.cluster_name = \"${var.cluster_name}\" AND resource.labels.namespace_name = \"${var.namespace}\" AND metric.type = \"kubernetes.io/container/memory/used_bytes\""
                }
              }
            }]
          }
        }
      ]
    }
  })
}