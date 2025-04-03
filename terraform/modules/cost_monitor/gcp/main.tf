/**
 * Módulo de Monitoramento de Custos para GCP
 * 
 * Este módulo configura ferramentas para monitorar, controlar e 
 * alertar sobre gastos no Google Cloud Platform.
 */

# Criar tópico do Pub/Sub para notificações de orçamento
resource "google_pubsub_topic" "budget_alerts" {
  name    = "${var.project_name}-${var.environment}-budget-alerts"
  project = var.project_id

  labels = var.tags
}

# Criar assinatura do Pub/Sub para processar as notificações
resource "google_pubsub_subscription" "budget_alerts" {
  name    = "${var.project_name}-${var.environment}-budget-alerts-sub"
  topic   = google_pubsub_topic.budget_alerts.name
  project = var.project_id

  # Configurações de expiração da assinatura
  expiration_policy {
    ttl = "" # Nunca expira
  }

  # Configurações de retenção de mensagens não confirmadas
  message_retention_duration = "604800s" # 7 dias

  labels = var.tags
}

# Criar orçamento e alertas no GCP
resource "google_billing_budget" "budget" {
  billing_account = var.billing_account_id
  display_name    = "${var.project_name}-${var.environment}-budget"

  # Definir o escopo do orçamento
  budget_filter {
    projects = ["projects/${var.project_id}"]
    labels = {
      environment = var.environment
      project     = var.project_name
    }
  }

  # Configurar o valor do orçamento
  amount {
    specified_amount {
      currency_code = var.budget_currency
      units         = var.budget_amount
    }
  }

  # Configura alertas em diferentes limites
  threshold_rules {
    threshold_percent = var.alert_threshold_percent / 100
    spend_basis       = "CURRENT_SPEND"
  }

  threshold_rules {
    threshold_percent = 1.0
    spend_basis       = "CURRENT_SPEND"
  }

  # Configurar alertar baseada em previsão de gastos
  threshold_rules {
    threshold_percent = 1.0
    spend_basis       = "FORECASTED_SPEND"
  }

  # Configurar notificações
  all_updates_rule {
    pubsub_topic = google_pubsub_topic.budget_alerts.id

    # Para enviar e-mails
    monitoring_notification_channels = var.notification_channel_ids

    # Habilitar alertas de gastos previstos
    disable_default_iam_recipients = false
  }
}

# Criar métricas personalizadas para monitoramento de custos
resource "google_monitoring_metric_descriptor" "cost_metric" {
  count        = var.environment == "prod" ? 1 : 0
  project      = var.project_id
  description  = "Métrica para monitorar custos por serviço no projeto ${var.project_name}"
  display_name = "Cost by Service"
  type         = "custom.googleapis.com/${var.project_name}/billing/cost_by_service"
  metric_kind  = "GAUGE"
  value_type   = "DOUBLE"
  unit         = "USD"

  labels {
    key         = "service"
    description = "Nome do serviço GCP"
    value_type  = "STRING"
  }

  labels {
    key         = "environment"
    description = "Ambiente"
    value_type  = "STRING"
  }
}

# Criar dashboard para visualização de custos
resource "google_monitoring_dashboard" "cost_dashboard" {
  count = var.environment == "prod" ? 1 : 0
  dashboard_json = jsonencode({
    displayName = "Custos e Utilização - ${var.project_name} (${var.environment})"
    gridLayout = {
      columns = "2"
      widgets = [
        {
          title = "Gastos Mensais"
          xyChart = {
            dataSets = [
              {
                timeSeriesQuery = {
                  timeSeriesFilter = {
                    filter = "metric.type=\"billing.googleapis.com/billing/monthly_cost\" resource.type=\"global\""
                    aggregation = {
                      alignmentPeriod  = "86400s"
                      perSeriesAligner = "ALIGN_MEAN"
                    }
                  }
                  unitOverride = "USD"
                }
                plotType = "LINE"
              }
            ]
            timeshiftDuration = "0s"
            yAxis = {
              label = "USD"
              scale = "LINEAR"
            }
          }
        },
        {
          title = "Gastos por Serviço"
          pieChart = {
            chartOptions = {
              mode = "STATS"
            }
            dataSets = [
              {
                timeSeriesQuery = {
                  timeSeriesFilter = {
                    filter = "metric.type=\"billing.googleapis.com/billing/monthly_cost\" resource.type=\"global\" AND metric.label.resource_type!=\"\""
                    secondaryAggregation = {
                      alignmentPeriod    = "2592000s"
                      perSeriesAligner   = "ALIGN_SUM"
                      crossSeriesReducer = "REDUCE_SUM"
                      groupByFields      = ["metric.label.resource_type"]
                    }
                  }
                }
              }
            ]
          }
        }
      ]
    }
  })
  project = var.project_id
}