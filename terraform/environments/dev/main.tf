# Configuração do ambiente de desenvolvimento

terraform {
  required_version = ">= 1.0.0"
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.36"
    }
  }

  # Configuração do backend remoto S3
  # 
  # IMPORTANTE: Credenciais AWS para o backend S3
  # As credenciais para acessar o S3 podem ser fornecidas de várias formas:
  # 1. Variáveis de ambiente AWS_ACCESS_KEY_ID e AWS_SECRET_ACCESS_KEY (recomendado)
  # 2. Perfil AWS compartilhado (~/.aws/credentials)
  # 3. Credenciais de instância EC2/ECS (se executando na AWS)
  #
  # Antes de inicializar o Terraform, verifique se o bucket existe com:
  # aws s3api head-bucket --bucket terraform-state-boilerplate-nestjs --region us-east-1
  backend "s3" {
    bucket         = "terraform-state-boilerplate-nestjs"
    key            = "dev/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-locks"

    # Configurações de segurança e desempenho
    sse_algorithm = "AES256"
    acl           = "private"

    # Define o perfil AWS a ser usado (se não estiver usando variáveis de ambiente)
    # profile        = "terraform"  # Descomente e ajuste conforme necessário

    # Configuração de endpoints personalizados (se usando S3 compatível como MinIO)
    # endpoint       = "custom-endpoint.example.com"  # Descomente se necessário

    # Definir como true para verificar a existência do bucket antes de usar
    skip_credentials_validation = false
    skip_metadata_api_check     = false
    skip_region_validation      = false
  }
}

# Carrega as configurações do arquivo config.yaml
locals {
  config       = yamldecode(file("${path.module}/config.yaml"))
  environment  = "dev"
  project_name = "boilerplate-nestjs"
  tags = {
    Environment = local.environment
    Project     = local.project_name
    ManagedBy   = "Terraform"
  }
}

# Configuração do provider DigitalOcean
provider "digitalocean" {
  token = sensitive(
    coalesce(
      # 1. Prioriza a variável de ambiente DIGITALOCEAN_TOKEN
      try(trimspace(nonsensitive(sensitive(coalesce(
        lookup(local.config.provider.digitalocean, "use_env", true) ? try(nonsensitive(sensitive(trimspace(coalesce(getenv("DIGITALOCEAN_TOKEN"), "")))), null) : null
      )))), null),
      # 2. Fallback para o token no arquivo config.yaml se estiver definido
      lookup(local.config.provider.digitalocean, "token", null),
      # 3. Último fallback para o arquivo local
      try(trimspace(file(lookup(local.config.provider.digitalocean, "token_file", "~/.digitalocean/token"))), null)
    )
  )
}

# Módulo de rede
module "network" {
  source = "../../modules/network/digital-ocean"

  environment  = local.environment
  project_name = local.project_name
  vpc_cidr     = local.config.network.vpc_cidr
}

# Módulo de banco de dados
module "database" {
  source = "../../modules/database/digital-ocean"

  environment    = local.environment
  project_name   = local.project_name
  instance_type  = local.config.database.instance_type
  engine_version = local.config.database.engine_version
  region         = local.config.provider.digitalocean.region
  vpc_id         = module.network.vpc_id
  vpc_cidr       = local.config.network.vpc_cidr

  depends_on = [module.network]
}

# Módulo de Kubernetes
module "kubernetes" {
  source = "../../modules/kubernetes/digital-ocean"

  environment        = local.environment
  project_name       = local.project_name
  region             = local.config.provider.digitalocean.region
  kubernetes_version = local.config.kubernetes.version
  node_size          = try(local.config.kubernetes.node_instance_types[0], "s-2vcpu-2gb")
  node_count         = local.config.kubernetes.desired_nodes
  min_nodes          = local.config.kubernetes.min_nodes
  max_nodes          = local.config.kubernetes.max_nodes
  vpc_id             = module.network.vpc_id
  tags               = local.tags

  depends_on = [module.network]
}

# Módulo de monitoramento de custos
module "cost_monitor" {
  source = "../../modules/cost_monitor/digital-ocean"

  environment          = local.environment
  project_name         = local.project_name
  budget_threshold     = local.config.cost.budget_amount
  monthly_budget_limit = local.config.cost.budget_amount * 30
  alert_emails         = local.config.cost.alert_emails
  tags                 = local.tags
}

# Módulo de monitoramento
module "monitoring" {
  source = "../../modules/monitoring/digital-ocean"

  environment         = local.environment
  project_name        = local.project_name
  cpu_threshold       = local.config.monitoring.alert_threshold_cpu
  memory_threshold    = local.config.monitoring.alert_threshold_memory
  notification_emails = local.config.cost.alert_emails
  service_name        = lookup(lookup(local.config.monitoring, "digitalocean", {}), "service_name", "${local.project_name}-${local.environment}-service")
  cluster_name        = lookup(lookup(local.config.monitoring, "digitalocean", {}), "cluster_name", "${local.project_name}-${local.environment}-cluster")
  service_endpoint    = lookup(lookup(local.config.monitoring, "digitalocean", {}), "service_endpoint", "https://api-dev.example.com/health")
  slack_channel       = lookup(lookup(local.config.monitoring, "digitalocean", {}), "slack_channel", "")
  slack_webhook_url   = lookup(lookup(local.config.monitoring, "digitalocean", {}), "slack_webhook_url", "")
  tags                = local.tags

  depends_on = [module.kubernetes]
}

# Outputs
output "vpc_id" {
  description = "ID da VPC criada"
  value       = module.network.vpc_id
}

output "vpc_name" {
  description = "Nome da VPC criada"
  value       = module.network.vpc_name
}

output "project_id" {
  description = "ID do projeto Digital Ocean"
  value       = module.network.project_id
}

output "database_connection_string" {
  description = "String de conexão para o banco de dados"
  value       = module.database.connection_string
  sensitive   = true
}

output "database_private_uri" {
  description = "URI privada do banco de dados (para acesso pela VPC)"
  value       = module.database.private_uri
  sensitive   = true
}

output "kubernetes_cluster_id" {
  description = "ID do cluster Kubernetes"
  value       = module.kubernetes.cluster_id
}

output "kubernetes_cluster_name" {
  description = "Nome do cluster Kubernetes"
  value       = module.kubernetes.cluster_name
}

output "kubernetes_endpoint" {
  description = "Endpoint da API do Kubernetes"
  value       = module.kubernetes.endpoint
  sensitive   = true
}

output "kubectl_config_command" {
  description = "Comando para configurar o kubectl local"
  value       = module.kubernetes.kubectl_config_command
}

output "monthly_cost_estimate" {
  description = "Estimativa mensal de custos"
  value = {
    database   = module.database.estimated_monthly_cost
    kubernetes = module.kubernetes.estimated_monthly_cost
    total      = module.cost_monitor.estimated_monthly_cost
  }
}

output "cost_optimization_tips" {
  description = "Dicas para otimização de custos"
  value       = module.cost_monitor.optimization_tips
}