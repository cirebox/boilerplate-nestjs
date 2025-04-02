# Configuração do ambiente de homologação (staging)

terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  
  # Configuração do backend remoto
  backend "s3" {
    bucket         = "terraform-state-boilerplate-nestjs"
    key            = "staging/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-locks"
  }
}

# Carrega as configurações do arquivo config.yaml
locals {
  config = yamldecode(file("${path.module}/config.yaml"))
  environment = "staging"
  project_name = "boilerplate-nestjs"
  tags = {
    Environment = local.environment
    Project     = local.project_name
    ManagedBy   = "Terraform"
  }
}

# Configuração do provider AWS
provider "aws" {
  region  = local.config.provider.aws.region
  profile = local.config.provider.aws.profile
  
  default_tags {
    tags = local.tags
  }
}

# Módulo de rede
module "network" {
  source = "../../modules/network/aws"
  
  environment = local.environment
  project_name = local.project_name
  vpc_cidr = local.config.network.vpc_cidr
  tags = local.tags
}

# Módulo de banco de dados
module "database" {
  source = "../../modules/database/aws"
  
  environment = local.environment
  project_name = local.project_name
  instance_type = local.config.database.instance_type
  engine_version = local.config.database.engine_version
  subnet_ids = module.network.private_subnet_ids
  vpc_id = module.network.vpc_id
  tags = local.tags
  
  # Configurações de controle de custos
  backup_retention_days = local.config.database.backup_retention_days
  skip_final_snapshot = local.config.database.skip_final_snapshot
  deletion_protection = local.config.database.deletion_protection
  
  # Configurações de escalabilidade
  allocated_storage = local.config.database.storage_gb
  max_allocated_storage = local.config.database.max_allocated_storage
  
  depends_on = [module.network]
}

# Módulo de Kubernetes
module "kubernetes" {
  source = "../../modules/kubernetes/aws"
  
  environment = local.environment
  project_name = local.project_name
  cluster_version = local.config.kubernetes.version
  node_instance_types = local.config.kubernetes.node_instance_types
  min_nodes = local.config.kubernetes.min_nodes
  max_nodes = local.config.kubernetes.max_nodes
  desired_nodes = local.config.kubernetes.desired_nodes
  vpc_id = module.network.vpc_id
  subnet_ids = module.network.private_subnet_ids
  tags = local.tags
  
  depends_on = [module.network]
}

# Módulo de monitoramento de custos
module "cost_monitor" {
  source = "../../modules/cost_monitor/aws"
  
  environment = local.environment
  project_name = local.project_name
  budget_amount = local.config.cost.budget_amount
  budget_currency = local.config.cost.budget_currency
  alert_threshold_percent = local.config.cost.alert_threshold_percent
  alert_emails = local.config.cost.alert_emails
  tags = local.tags
}

# Módulo de monitoramento
module "monitoring" {
  source = "../../modules/monitoring/aws"
  
  environment = local.environment
  project_name = local.project_name
  cpu_threshold = local.config.monitoring.alert_threshold_cpu
  memory_threshold = local.config.monitoring.alert_threshold_memory
  notification_emails = local.config.cost.alert_emails
  service_name = lookup(lookup(local.config.monitoring, "aws", {}), "service_name", "${local.project_name}-${local.environment}-service")
  cluster_name = lookup(lookup(local.config.monitoring, "aws", {}), "cluster_name", "${local.project_name}-${local.environment}-cluster")
  webhook_url = lookup(lookup(local.config.monitoring, "aws", {}), "webhook_url", "")
  kubernetes_service = lookup(lookup(local.config.monitoring, "aws", {}), "kubernetes_service", false)
  namespace = lookup(local.config.monitoring, "namespace", "staging")
  tags = local.tags
  
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

output "private_subnet_ids" {
  description = "IDs das subnets privadas"
  value       = module.network.private_subnet_ids
}

output "public_subnet_ids" {
  description = "IDs das subnets públicas"
  value       = module.network.public_subnet_ids
}

output "database_endpoint" {
  description = "Endpoint para acessar o banco de dados"
  value       = module.database.endpoint
  sensitive   = true
}

output "database_instance_id" {
  description = "ID da instância do banco de dados"
  value       = module.database.db_instance_id
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
  value       = module.kubernetes.kubectl_config_command
}

output "estimated_monthly_cost" {
  description = "Estimativa mensal de custos"
  value       = module.cost_monitor.estimated_monthly_cost
}

output "cost_optimization_tips" {
  description = "Dicas para otimização de custos"
  value       = module.cost_monitor.optimization_tips
}

output "cloudwatch_dashboard_url" {
  description = "URL para o dashboard do CloudWatch"
  value       = module.monitoring.dashboard_url
}