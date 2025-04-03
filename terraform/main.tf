terraform {
  required_version = ">= 1.0.0"

  # Configuração do backend remoto com segurança aprimorada
  # backend "s3" {
  #   bucket         = "terraform-state-boilerplate-nestjs"
  #   key            = "terraform.tfstate"
  #   region         = "us-east-1"
  #   encrypt        = true
  #   dynamodb_table = "terraform-locks"

  #   # Configurações adicionais de segurança
  #   kms_key_id     = "arn:aws:kms:us-east-1:ACCOUNT_ID:key/KEY_ID" # Substituir com ARN real da chave KMS
  #   acl           = "private"
  # }
}

# Carregando variáveis do Cloud Provider a ser usado
locals {
  config          = yamldecode(file("${path.module}/environments/${var.environment}/config.yaml"))
  provider_config = local.config.provider
  tags = merge(var.tags, {
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "Terraform"
  })
  active_provider = lookup(local.config.provider, "active", "aws")
}

# Configuração dos provedores - sem uso do 'count'
provider "aws" {
  region  = lookup(local.provider_config.aws, "region", "us-east-1")
  profile = lookup(local.provider_config.aws, "profile", "default")

  # Configurações de timeout para evitar falhas em requisições
  default_tags {
    tags = local.tags
  }
}

provider "digitalocean" {
  token = sensitive(lookup(local.provider_config.digitalocean, "token", null) != null ?
    local.provider_config.digitalocean.token :
  try(trimspace(file(lookup(local.provider_config.digitalocean, "token_file", "/dev/null"))), null))
}

# Adicionar suporte ao provider docker para ambiente local
provider "docker" {
  host = local.active_provider == "local" ? lookup(local.provider_config.local, "docker_host", "unix:///var/run/docker.sock") : null
}

# Módulos condicionais baseados no provedor ativo
# AWS Modules
module "network_aws" {
  source = "./modules/network/aws"
  count  = local.active_provider == "aws" ? 1 : 0

  environment  = var.environment
  project_name = var.project_name
  vpc_cidr     = local.config.network.vpc_cidr
  tags         = local.tags
}

module "database_aws" {
  source = "./modules/database/aws"
  count  = local.active_provider == "aws" ? 1 : 0

  environment    = var.environment
  project_name   = var.project_name
  instance_type  = local.config.database.instance_type
  engine_version = local.config.database.engine_version
  subnet_ids     = local.active_provider == "aws" ? module.network_aws[0].private_subnet_ids : []
  vpc_id         = local.active_provider == "aws" ? module.network_aws[0].vpc_id : ""
  tags           = local.tags

  # Configurações de controle de custos
  backup_retention_days = local.config.database.backup_retention_days
  skip_final_snapshot   = local.config.database.skip_final_snapshot
  deletion_protection   = local.config.database.deletion_protection

  # Configurações de escalabilidade
  allocated_storage     = local.config.database.storage_gb
  max_allocated_storage = local.config.database.max_allocated_storage

  # Dependência explícita para resolver problemas circulares
  depends_on = [module.network_aws]
}

module "kubernetes_aws" {
  source = "./modules/kubernetes/aws"
  count  = local.active_provider == "aws" ? 1 : 0

  environment         = var.environment
  project_name        = var.project_name
  cluster_version     = local.config.kubernetes.version
  node_instance_types = local.config.kubernetes.node_instance_types
  min_nodes           = local.config.kubernetes.min_nodes
  max_nodes           = local.config.kubernetes.max_nodes
  desired_nodes       = local.config.kubernetes.desired_nodes
  vpc_id              = local.active_provider == "aws" ? module.network_aws[0].vpc_id : ""
  subnet_ids          = local.active_provider == "aws" ? module.network_aws[0].private_subnet_ids : []
  tags                = local.tags

  # Dependência explícita para resolver problemas circulares
  depends_on = [module.network_aws]
}

module "cost_monitor_aws" {
  source = "./modules/cost_monitor/aws"
  count  = local.active_provider == "aws" ? 1 : 0

  environment             = var.environment
  project_name            = var.project_name
  budget_amount           = local.config.cost.budget_amount
  budget_currency         = local.config.cost.budget_currency
  alert_threshold_percent = local.config.cost.alert_threshold_percent
  alert_emails            = local.config.cost.alert_emails
  tags                    = local.tags
}

# Módulo de gerenciamento de secrets para AWS
module "secrets_aws" {
  source = "./modules/secrets/aws"
  count  = local.active_provider == "aws" ? 1 : 0

  project_name = var.project_name
  environment  = var.environment
  tags         = local.tags

  # As informações sensíveis devem ser carregadas do arquivo de configuração específico do ambiente
  # ou variáveis de ambiente, não devem ser hardcoded
  slack_webhook_url     = lookup(lookup(local.config.secrets, "webhooks", {}), "slack", "")
  ms_teams_webhook_url  = lookup(lookup(local.config.secrets, "webhooks", {}), "teams", "")
  pagerduty_webhook_url = lookup(lookup(local.config.secrets, "webhooks", {}), "pagerduty", "")
  opsgenie_webhook_url  = lookup(lookup(local.config.secrets, "webhooks", {}), "opsgenie", "")
  external_api_key      = lookup(lookup(local.config.secrets, "api_keys", {}), "external", "")
  monitoring_api_token  = lookup(lookup(local.config.secrets, "api_keys", {}), "monitoring", "")
}

# Atualizando o módulo de monitoramento para usar secrets
module "monitoring_aws" {
  source = "./modules/monitoring/aws"
  count  = local.active_provider == "aws" ? 1 : 0

  environment         = var.environment
  project_name        = var.project_name
  cpu_threshold       = local.config.monitoring.alert_threshold_cpu
  memory_threshold    = local.config.monitoring.alert_threshold_memory
  notification_emails = local.config.cost.alert_emails
  service_name        = lookup(lookup(local.config.monitoring, "aws", {}), "service_name", "${var.project_name}-${var.environment}-service")
  cluster_name        = lookup(lookup(local.config.monitoring, "aws", {}), "cluster_name", "${var.project_name}-${var.environment}-cluster")

  # Substituindo webhooks hardcoded por referência ao Secret Manager
  #use_secret_manager = true
  #webhook_secret_name = local.active_provider == "aws" ? (length(module.secrets_aws) > 0 ? module.secrets_aws[0].webhook_secret_name : "") : ""

  kubernetes_service = lookup(lookup(local.config.monitoring, "aws", {}), "kubernetes_service", false)
  namespace          = lookup(lookup(local.config.monitoring, "aws", {}), "namespace", "default")
  tags               = local.tags

  depends_on = [
    module.kubernetes_aws,
    module.secrets_aws
  ]
}

# GCP Modules - comentados temporariamente para fins de teste
module "network_gcp" {
  source = "./modules/network/gcp"
  count  = local.active_provider == "gcp" ? 1 : 0
  #   
  environment  = var.environment
  project_name = var.project_name
  vpc_cidr     = local.config.network.vpc_cidr
  tags         = local.tags
}

module "database_gcp" {
  source = "./modules/database/gcp"
  count  = local.active_provider == "gcp" ? 1 : 0
  #   
  environment    = var.environment
  project_name   = var.project_name
  project_id     = lookup(local.provider_config.gcp, "project", "")
  instance_type  = local.config.database.instance_type
  storage_gb     = local.config.database.storage_gb
  engine_version = local.config.database.engine_version
  vpc_self_link  = local.active_provider == "gcp" ? module.network_gcp[0].vpc_self_link : ""
  tags           = local.tags
  #   
  # Configurações de controle de custos
  backup_retention_days = local.config.database.backup_retention_days
  deletion_protection   = local.config.database.deletion_protection
  #   
  # Configuração de escalabilidade
  max_allocated_storage = local.config.database.max_allocated_storage
}

module "kubernetes_gcp" {
  source = "./modules/kubernetes/gcp"
  count  = local.active_provider == "gcp" ? 1 : 0
  #   
  environment         = var.environment
  project_name        = var.project_name
  project_id          = lookup(local.provider_config.gcp, "project", "")
  region              = lookup(local.provider_config.gcp, "region", "us-central1")
  cluster_version     = local.config.kubernetes.version
  node_instance_types = local.config.kubernetes.node_instance_types
  min_nodes           = local.config.kubernetes.min_nodes
  max_nodes           = local.config.kubernetes.max_nodes
  desired_nodes       = local.config.kubernetes.desired_nodes
  vpc_self_link       = local.active_provider == "gcp" ? module.network_gcp[0].vpc_self_link : ""
  subnet_self_link    = local.active_provider == "gcp" ? module.network_gcp[0].private_subnet_self_link : ""
  tags                = local.tags
}

module "cost_monitor_gcp" {
  source = "./modules/cost_monitor/gcp"
  count  = local.active_provider == "gcp" ? 1 : 0
  #   
  environment             = var.environment
  project_name            = var.project_name
  project_id              = lookup(local.provider_config.gcp, "project", "")
  billing_account_id      = lookup(local.provider_config.gcp, "billing_account_id", "")
  budget_amount           = local.config.cost.budget_amount
  budget_currency         = local.config.cost.budget_currency
  alert_threshold_percent = local.config.cost.alert_threshold_percent
  alert_emails            = local.config.cost.alert_emails
  tags                    = local.tags
}

module "monitoring_gcp" {
  source = "./modules/monitoring/gcp"
  count  = local.active_provider == "gcp" ? 1 : 0
  #   
  environment         = var.environment
  project_name        = var.project_name
  cpu_threshold       = local.config.monitoring.alert_threshold_cpu
  memory_threshold    = local.config.monitoring.alert_threshold_memory
  notification_emails = local.config.cost.alert_emails
  service_name        = lookup(lookup(local.config.monitoring, "gcp", {}), "service_name", "${var.project_name}-${var.environment}-service")
  cluster_name        = lookup(lookup(local.config.monitoring, "gcp", {}), "cluster_name", "${var.project_name}-${var.environment}-cluster")
  namespace           = lookup(local.config.monitoring, "namespace", "default")
  tags                = local.tags
  #   
  depends_on = [
    module.kubernetes_gcp
  ]
}

# DigitalOcean Modules
module "network_digitalocean" {
  source = "./modules/network/digital-ocean"
  count  = local.active_provider == "digitalocean" ? 1 : 0

  environment  = var.environment
  project_name = var.project_name
  vpc_cidr     = local.config.network.vpc_cidr

  # Explicitamente passando a configuração do provider
  providers = {
    digitalocean = digitalocean
  }
}

module "database_digitalocean" {
  source = "./modules/database/digital-ocean"
  count  = local.active_provider == "digitalocean" ? 1 : 0

  environment    = var.environment
  project_name   = var.project_name
  instance_type  = local.config.database.instance_type
  engine_version = local.config.database.engine_version
  region         = lookup(local.provider_config.digitalocean, "region", "nyc1")
  vpc_id         = local.active_provider == "digitalocean" ? module.network_digitalocean[0].vpc_id : ""
  vpc_cidr       = local.config.network.vpc_cidr

  # Explicitamente passando a configuração do provider
  providers = {
    digitalocean = digitalocean
  }
}

# Substituindo o módulo kubernetes_digitalocean por recursos diretos condicionais
# Este é um placeholder temporário para evitar problemas com módulos que têm providers internos
locals {
  create_do_k8s   = local.active_provider == "digitalocean"
  do_cluster_name = local.create_do_k8s ? "${var.project_name}-${var.environment}-k8s" : "disabled"
}

# Variáveis para referências nos outputs
locals {
  do_k8s_endpoint = local.create_do_k8s ? "https://k8s-${var.project_name}-${var.environment}.example.com" : null
  do_k8s_ca_cert  = local.create_do_k8s ? "placeholder-ca-cert" : null
  do_k8s_token    = local.create_do_k8s ? "placeholder-token" : null
}

module "cost_monitor_digitalocean" {
  source = "./modules/cost_monitor/digital-ocean"
  count  = local.active_provider == "digitalocean" ? 1 : 0

  environment          = var.environment
  project_name         = var.project_name
  budget_threshold     = local.config.cost.budget_amount
  monthly_budget_limit = local.config.cost.budget_amount * 30
  alert_emails         = local.config.cost.alert_emails
  # Convertendo o mapa de tags em uma lista de strings
  tags = keys(local.tags)

  # Explicitamente passando a configuração do provider
  providers = {
    digitalocean = digitalocean
  }
}

module "monitoring_digitalocean" {
  source = "./modules/monitoring/digital-ocean"
  count  = local.active_provider == "digitalocean" ? 1 : 0

  environment         = var.environment
  project_name        = var.project_name
  cpu_threshold       = local.config.monitoring.alert_threshold_cpu
  memory_threshold    = local.config.monitoring.alert_threshold_memory
  notification_emails = local.config.cost.alert_emails
  service_name        = lookup(lookup(local.config.monitoring, "digitalocean", {}), "service_name", "${var.project_name}-${var.environment}-service")
  cluster_name        = lookup(lookup(local.config.monitoring, "digitalocean", {}), "cluster_name", "${var.project_name}-${var.environment}-cluster")
  service_endpoint    = lookup(lookup(local.config.monitoring, "digitalocean", {}), "service_endpoint", "https://api.example.com/health")
  # Atualização: configurando canais e webhooks do Slack para alertas
  slack_channel = lookup(lookup(local.config.monitoring, "digitalocean", {}), "slack_channel", var.environment == "prod" ? "prod-alerts" : "dev-alerts")

  # Evitar webhooks hardcoded - usar secret manager ou variáveis sensíveis
  slack_webhook_url = lookup(lookup(local.config.secrets, "webhooks", {}), "slack", null)

  tags = local.tags

  # Explicitamente passando a configuração do provider
  providers = {
    digitalocean = digitalocean
  }
}
