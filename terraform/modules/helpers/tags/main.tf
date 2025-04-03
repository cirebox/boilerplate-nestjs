locals {
  provider_prefixes = {
    aws          = "aws"
    gcp          = "gcp"
    azure        = "azure"
    digitalocean = "do"
    local        = "local"
  }

  # Tags comuns para todos os recursos
  common_tags = {
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "Terraform"
    Provisioner = "CI/CD"
    Timestamp   = formatdate("YYYY-MM-DD-hh-mm-ss", timestamp())
  }

  # Combinação de tags comuns com tags específicas
  all_tags = merge(local.common_tags, var.extra_tags)

  # Tags formatadas para cada provedor
  provider_tags = {
    # AWS usa a estrutura padrão de tags
    aws = local.all_tags

    # GCP precisa de uma formatação específica para labels
    gcp = {
      for key, value in local.all_tags :
      lower(replace(key, "/[^a-zA-Z0-9_]/", "_")) => lower(replace(value, "/[^a-zA-Z0-9_]/", "_"))
    }

    # Azure tem seu próprio formato
    azure = local.all_tags

    # DigitalOcean usa tags como strings em vez de map
    digitalocean = [
      for key, value in local.all_tags :
      lower("${key}:${value}")
    ]

    # Local pode usar o formato padrão
    local = local.all_tags
  }
}

# Output as tags formatadas para o provedor especificado
output "tags" {
  description = "Tags formatadas para o provedor especificado"
  value       = lookup(local.provider_tags, var.provider_name, local.all_tags)
}

# Output específico para cada provedor
output "aws_tags" {
  description = "Tags formatadas para AWS"
  value       = local.provider_tags.aws
}

output "gcp_labels" {
  description = "Labels formatados para GCP"
  value       = local.provider_tags.gcp
}

output "azure_tags" {
  description = "Tags formatadas para Azure"
  value       = local.provider_tags.azure
}

output "digitalocean_tags" {
  description = "Tags formatadas para DigitalOcean"
  value       = local.provider_tags.digitalocean
}

output "local_tags" {
  description = "Tags formatadas para ambiente local"
  value       = local.provider_tags.local
}