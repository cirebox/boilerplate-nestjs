output "webhook_secret_arn" {
  description = "ARN do segredo que contém as URLs de webhook"
  value       = aws_secretsmanager_secret.webhook_urls.arn
}

output "api_credentials_secret_arn" {
  description = "ARN do segredo que contém as credenciais de API"
  value       = aws_secretsmanager_secret.api_credentials.arn
}

output "eks_secrets_access_role_arn" {
  description = "ARN da role IAM para acesso aos secrets pelo EKS"
  value       = aws_iam_role.eks_secrets_access.arn
}

output "webhook_secret_name" {
  description = "Nome do segredo que contém as URLs de webhook"
  value       = aws_secretsmanager_secret.webhook_urls.name
}

output "api_credentials_secret_name" {
  description = "Nome do segredo que contém as credenciais de API"
  value       = aws_secretsmanager_secret.api_credentials.name
}