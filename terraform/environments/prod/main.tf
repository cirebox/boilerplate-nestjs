# Configuração do ambiente de produção

terraform {
  required_version = ">= 1.0.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 4.0"
    }
  }

  # Configuração do backend remoto
  backend "s3" {
    bucket         = "terraform-state-boilerplate-nestjs"
    key            = "prod/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-locks"
  }
}

# Carrega as configurações do arquivo config.yaml
locals {
  config       = yamldecode(file("${path.module}/config.yaml"))
  environment  = "prod"
  project_name = "boilerplate-nestjs"
  tags = {
    Environment = local.environment
    Project     = local.project_name
    ManagedBy   = "Terraform"
  }
}

# Configuração do provider GCP
provider "google" {
  project     = local.config.provider.gcp.project
  region      = local.config.provider.gcp.region
  zone        = local.config.provider.gcp.zone
  credentials = file(local.config.provider.gcp.credentials_file)
}

# Módulo de rede
module "network" {
  source = "../../modules/network/gcp"

  environment  = local.environment
  project_name = local.project_name
  vpc_cidr     = local.config.network.vpc_cidr
  tags         = local.tags
}

# Módulo de banco de dados
module "database" {
  source = "../../modules/database/gcp"

  environment    = local.environment
  project_name   = local.project_name
  project_id     = local.config.provider.gcp.project
  instance_type  = local.config.database.instance_type
  storage_gb     = local.config.database.storage_gb
  engine_version = local.config.database.engine_version
  vpc_self_link  = module.network.vpc_self_link
  tags           = local.tags

  # Configurações de controle de custos
  backup_retention_days = local.config.database.backup_retention_days
  deletion_protection   = local.config.database.deletion_protection

  # Configuração de escalabilidade
  max_allocated_storage = local.config.database.max_allocated_storage

  depends_on = [module.network]
}

# Módulo de Kubernetes
module "kubernetes" {
  source = "../../modules/kubernetes/gcp"

  environment         = local.environment
  project_name        = local.project_name
  project_id          = local.config.provider.gcp.project
  region              = local.config.provider.gcp.region
  cluster_version     = local.config.kubernetes.version
  node_instance_types = local.config.kubernetes.node_instance_types
  min_nodes           = local.config.kubernetes.min_nodes
  max_nodes           = local.config.kubernetes.max_nodes
  desired_nodes       = local.config.kubernetes.desired_nodes
  vpc_self_link       = module.network.vpc_self_link
  subnet_self_link    = module.network.private_subnet_self_link
  tags                = local.tags

  depends_on = [module.network]
}

# Módulo de monitoramento de custos
module "cost_monitor" {
  source = "../../modules/cost_monitor/gcp"

  environment             = local.environment
  project_name            = local.project_name
  project_id              = local.config.provider.gcp.project
  billing_account_id      = local.config.provider.gcp.billing_account_id
  budget_amount           = local.config.cost.budget_amount
  budget_currency         = local.config.cost.budget_currency
  alert_threshold_percent = local.config.cost.alert_threshold_percent
  alert_emails            = local.config.cost.alert_emails
  tags                    = local.tags
}

# Módulo de monitoramento
module "monitoring" {
  source = "../../modules/monitoring/gcp"

  environment         = local.environment
  project_name        = local.project_name
  cpu_threshold       = local.config.monitoring.alert_threshold_cpu
  memory_threshold    = local.config.monitoring.alert_threshold_memory
  notification_emails = local.config.cost.alert_emails
  service_name        = lookup(lookup(local.config.monitoring, "gcp", {}), "service_name", "${local.project_name}-${local.environment}-service")
  cluster_name        = lookup(lookup(local.config.monitoring, "gcp", {}), "cluster_name", "${local.project_name}-${local.environment}-cluster")
  namespace           = lookup(local.config.monitoring, "namespace", "production")
  tags                = local.tags

  depends_on = [module.kubernetes]
}

# Outputs
output "vpc_self_link" {
  description = "Self link da VPC criada"
  value       = module.network.vpc_self_link
}

output "vpc_name" {
  description = "Nome da VPC criada"
  value       = module.network.vpc_name
}

output "private_subnet_self_link" {
  description = "Self link da subnet privada"
  value       = module.network.private_subnet_self_link
}

output "public_subnet_self_link" {
  description = "Self link da subnet pública"
  value       = module.network.public_subnet_self_link
}

output "database_connection_name" {
  description = "Nome da conexão do banco de dados"
  value       = module.database.connection_name
}

output "database_endpoint" {
  description = "Endpoint para acessar o banco de dados"
  value       = module.database.endpoint
  sensitive   = true
}

output "database_instance_name" {
  description = "Nome da instância do banco de dados"
  value       = module.database.db_instance_name
}

output "kubernetes_cluster_name" {
  description = "Nome do cluster Kubernetes"
  value       = module.kubernetes.cluster_name
}

output "kubernetes_cluster_endpoint" {
  description = "Endpoint da API do Kubernetes"
  value       = module.kubernetes.cluster_endpoint
  sensitive   = true
}

output "kubernetes_config_command" {
  description = "Comando para configurar o kubectl local"
  value       = "gcloud container clusters get-credentials ${module.kubernetes.cluster_name} --region ${local.config.provider.gcp.region} --project ${local.config.provider.gcp.project}"
}

output "estimated_monthly_cost" {
  description = "Estimativa mensal de custos"
  value       = module.cost_monitor.estimated_monthly_cost
}

output "cost_optimization_tips" {
  description = "Dicas para otimização de custos"
  value       = module.cost_monitor.optimization_tips
}

output "monitoring_dashboard_url" {
  description = "URL para o dashboard de monitoramento"
  value       = "https://console.cloud.google.com/monitoring/dashboards?project=${local.config.provider.gcp.project}"
}