/**
 * Módulo para gerenciamento seguro de secrets
 * 
 * Este módulo utiliza o AWS Secrets Manager para armazenar
 * e gerenciar credenciais e URLs sensíveis de forma segura.
 */

resource "aws_secretsmanager_secret" "webhook_urls" {
  name                    = "${var.project_name}-${var.environment}-webhook-urls"
  description             = "URLs de webhooks para alertas e notificações"
  recovery_window_in_days = var.environment == "prod" ? 30 : 7
  
  tags = var.tags
}

resource "aws_secretsmanager_secret_version" "webhook_urls" {
  secret_id     = aws_secretsmanager_secret.webhook_urls.id
  secret_string = jsonencode({
    slack_alerts_webhook = var.slack_webhook_url
    teams_webhook        = var.ms_teams_webhook_url
    pagerduty_webhook    = var.pagerduty_webhook_url
    opsgenie_webhook     = var.opsgenie_webhook_url
  })
}

# Secret para credenciais de API
resource "aws_secretsmanager_secret" "api_credentials" {
  name                    = "${var.project_name}-${var.environment}-api-credentials"
  description             = "Credenciais de API para serviços externos"
  recovery_window_in_days = var.environment == "prod" ? 30 : 7
  
  tags = var.tags
}

resource "aws_secretsmanager_secret_version" "api_credentials" {
  secret_id     = aws_secretsmanager_secret.api_credentials.id
  secret_string = jsonencode({
    external_api_key     = var.external_api_key
    monitoring_api_token = var.monitoring_api_token
  })
}

# IAM Role para permitir acesso aos segredos pelo EKS
resource "aws_iam_role" "eks_secrets_access" {
  name = "${var.project_name}-${var.environment}-eks-secrets-access"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
      },
    ]
  })

  tags = var.tags
}

# Política para permitir acesso aos segredos específicos
resource "aws_iam_policy" "secrets_access_policy" {
  name        = "${var.project_name}-${var.environment}-secrets-access"
  description = "Permite acesso aos secrets específicos do projeto"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Effect = "Allow"
        Resource = [
          aws_secretsmanager_secret.webhook_urls.arn,
          aws_secretsmanager_secret.api_credentials.arn
        ]
      }
    ]
  })
}