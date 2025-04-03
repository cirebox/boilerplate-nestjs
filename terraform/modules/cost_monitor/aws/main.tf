/**
 * Módulo de Monitoramento de Custos AWS
 * 
 * Este módulo implementa o monitoramento de custos e alertas de orçamento
 * para controlar os gastos na AWS.
 */

locals {
  account_id = data.aws_caller_identity.current.account_id
}

# Obtém o ID da conta atual
data "aws_caller_identity" "current" {}

# Configura um orçamento para controle de custos
resource "aws_budgets_budget" "monthly" {
  name              = "${var.project_name}-${var.environment}-monthly-budget"
  budget_type       = "COST"
  limit_amount      = var.budget_amount
  limit_unit        = var.budget_currency
  time_unit         = "MONTHLY"
  time_period_start = formatdate("YYYY-MM-01_00:00", timestamp())

  # Filtrar por tags específicas do projeto
  cost_filter {
    name = "TagKeyValue"
    values = [
      "user:Project$${var.project_name}",
      "user:Environment$${var.environment}"
    ]
  }

  # Notificação quando atingir 80% do orçamento
  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = var.alert_threshold_percent
    threshold_type             = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_email_addresses = var.alert_emails
    subscriber_sns_topic_arns  = []
  }

  # Notificação quando atingir 100% do orçamento
  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 100
    threshold_type             = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_email_addresses = var.alert_emails
    subscriber_sns_topic_arns  = []
  }

  # Notificação de previsão quando o gasto está projetado para ultrapassar o orçamento
  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 100
    threshold_type             = "PERCENTAGE"
    notification_type          = "FORECASTED"
    subscriber_email_addresses = var.alert_emails
    subscriber_sns_topic_arns  = []
  }
}

# Cria um relatório de custos e uso para análises mais detalhadas
resource "aws_cur_report_definition" "cost_report" {
  report_name                = "${var.project_name}-${var.environment}-cost-report"
  time_unit                  = "DAILY"
  format                     = "Parquet"
  compression                = "Parquet"
  additional_schema_elements = ["RESOURCES"]
  s3_bucket                  = aws_s3_bucket.cost_reports.id
  s3_region                  = aws_s3_bucket.cost_reports.region
  s3_prefix                  = "cost-reports"
  report_versioning          = "OVERWRITE_REPORT"

  depends_on = [aws_s3_bucket_policy.cost_reports]
}

# Bucket S3 para armazenar relatórios de custo
resource "aws_s3_bucket" "cost_reports" {
  bucket = "${var.project_name}-${var.environment}-cost-reports-${local.account_id}"

  tags = var.tags
}

# Configuração de ciclo de vida para economizar custos
resource "aws_s3_bucket_lifecycle_configuration" "cost_reports_lifecycle" {
  bucket = aws_s3_bucket.cost_reports.id

  rule {
    id     = "archive-old-reports"
    status = "Enabled"

    filter {
      prefix = "cost-reports/"
    }

    transition {
      days          = 90
      storage_class = "STANDARD_IA"
    }

    expiration {
      days = 365
    }
  }
}

# Políticas de bucket para permitir acesso ao AWS Cost and Usage Report
resource "aws_s3_bucket_policy" "cost_reports" {
  bucket = aws_s3_bucket.cost_reports.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCURPut"
        Effect = "Allow"
        Principal = {
          Service = "billingreports.amazonaws.com"
        }
        Action = [
          "s3:PutObject"
        ]
        Resource = "${aws_s3_bucket.cost_reports.arn}/*"
      },
      {
        Sid    = "AllowCURList"
        Effect = "Allow"
        Principal = {
          Service = "billingreports.amazonaws.com"
        }
        Action = [
          "s3:ListBucket"
        ]
        Resource = aws_s3_bucket.cost_reports.arn
      }
    ]
  })
}

# Habilitar o Cost Explorer se solicitado
resource "aws_ce_cost_category" "environment" {
  count        = var.enable_cost_explorer ? 1 : 0
  name         = "${var.project_name}-environments"
  rule_version = "CostCategoryExpression.v1"

  rule {
    value = "Desenvolvimento"

    rule {
      dimension {
        key           = "LINKED_ACCOUNT_NAME" # Usado um valor válido da lista suportada
        values        = ["dev"]
        match_options = ["EQUALS"]
      }
    }
  }

  rule {
    value = "Homologação"

    rule {
      dimension {
        key           = "LINKED_ACCOUNT_NAME"
        values        = ["staging"]
        match_options = ["EQUALS"]
      }
    }
  }

  rule {
    value = "Produção"

    rule {
      dimension {
        key           = "LINKED_ACCOUNT_NAME"
        values        = ["prod"]
        match_options = ["EQUALS"]
      }
    }
  }

  rule {
    value = "Outros"
    type  = "REGULAR"
  }
}

# Criar alarmes CloudWatch para recursos custosos
resource "aws_cloudwatch_metric_alarm" "billing_alarm" {
  alarm_name          = "${var.project_name}-${var.environment}-billing-alarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "EstimatedCharges"
  namespace           = "AWS/Billing"
  period              = "21600" # 6 horas
  statistic           = "Maximum"
  threshold           = var.budget_amount * (var.alert_threshold_percent / 100)
  alarm_description   = "Este alarme é acionado quando os gastos estimados ultrapassam ${var.alert_threshold_percent}% do orçamento mensal (${var.budget_amount} ${var.budget_currency})"

  dimensions = {
    Currency = var.budget_currency
  }

  alarm_actions = [aws_sns_topic.billing_alerts.arn]
}

# Tópico SNS para notificações de gastos
resource "aws_sns_topic" "billing_alerts" {
  name = "${var.project_name}-${var.environment}-billing-alerts"

  tags = var.tags
}

# Assinaturas de e-mail para o tópico SNS
resource "aws_sns_topic_subscription" "email_subscriptions" {
  count     = length(var.alert_emails)
  topic_arn = aws_sns_topic.billing_alerts.arn
  protocol  = "email"
  endpoint  = var.alert_emails[count.index]
}