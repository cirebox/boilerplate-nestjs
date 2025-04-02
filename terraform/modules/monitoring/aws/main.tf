terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

locals {
  # Determinar o namespace correto baseado no tipo de serviço
  service_type = var.kubernetes_service ? "AWS/EKS" : "AWS/ECS"

  # Configurar as dimensões corretas baseadas no tipo de serviço
  dimensions = var.kubernetes_service ? {
    ClusterName = var.cluster_name
    Namespace   = var.namespace
    } : {
    ServiceName = var.service_name
    ClusterName = var.cluster_name
  }
}

# SNS Topic para os alertas
resource "aws_sns_topic" "alerts" {
  name = "${var.environment}-${var.project_name}-alerts"
}

# Email subscriptions para os alertas
resource "aws_sns_topic_subscription" "email" {
  count     = length(var.notification_emails)
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.notification_emails[count.index]
}

# Webhook subscription para o serviço externo
resource "aws_sns_topic_subscription" "webhook" {
  count     = var.webhook_url != "" ? 1 : 0
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "https"
  endpoint  = var.webhook_url
}

# Alerta de CPU alto
resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  alarm_name          = "${var.environment}-${var.project_name}-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = var.kubernetes_service ? "pod_cpu_utilization" : "CPUUtilization"
  namespace           = local.service_type
  period              = "300"
  statistic           = "Average"
  threshold           = var.cpu_threshold
  alarm_description   = "Monitoramento de CPU alta"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  ok_actions          = [aws_sns_topic.alerts.arn]

  dimensions = local.dimensions
}

# Alerta de Memória alta
resource "aws_cloudwatch_metric_alarm" "high_memory" {
  alarm_name          = "${var.environment}-${var.project_name}-high-memory"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = var.kubernetes_service ? "pod_memory_utilization" : "MemoryUtilization"
  namespace           = local.service_type
  period              = "300"
  statistic           = "Average"
  threshold           = var.memory_threshold
  alarm_description   = "Monitoramento de memória alta"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  ok_actions          = [aws_sns_topic.alerts.arn]

  dimensions = local.dimensions
}