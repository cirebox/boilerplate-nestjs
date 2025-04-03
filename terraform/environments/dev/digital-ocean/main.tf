/**
 * Configuração do ambiente de desenvolvimento para Digital Ocean
 * 
 * Este arquivo configura a infraestrutura de desenvolvimento no Digital Ocean
 * com configurações otimizadas para baixo custo.
 */

terraform {
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.36"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5.1"
    }
  }

  backend "s3" {
    endpoint                    = "https://nyc3.digitaloceanspaces.com"
    key                         = "terraform/dev/terraform.tfstate"
    skip_credentials_validation = true
    skip_metadata_api_check     = true
  }

  required_version = ">= 1.0.0"
}

# Configurar o provedor Digital Ocean
provider "digitalocean" {
  token = var.do_token
}

# Configurar o provedor Kubernetes (será configurado depois da criação do cluster)
provider "kubernetes" {
  host                   = module.kubernetes.endpoint
  token                  = var.do_token
  cluster_ca_certificate = base64decode(module.kubernetes.kube_config)
}

# Módulo de rede
module "network" {
  source = "../../../modules/network/digital-ocean"

  project_name         = var.project_name
  environment          = "dev"
  region               = var.region
  vpc_cidr             = "10.0.0.0/16"
  create_loadbalancer  = false
  ssh_source_addresses = var.ssh_source_addresses
}

# Módulo de banco de dados (configuração mínima para desenvolvimento)
module "database" {
  source = "../../../modules/database/digital-ocean"

  project_name   = var.project_name
  environment    = "dev"
  region         = var.region
  vpc_id         = module.network.vpc_id
  vpc_cidr       = module.network.vpc_cidr
  instance_type  = "db-s-1vcpu-1gb" # Menor tamanho para economizar custos
  engine         = "pg"
  engine_version = "14"
  allowed_ips    = var.database_allowed_ips
}

# Módulo Kubernetes (DOKS)
module "kubernetes" {
  source = "../../../modules/kubernetes/digital-ocean"

  project_name       = var.project_name
  environment        = "dev"
  region             = var.region
  vpc_id             = module.network.vpc_id
  node_size          = "s-1vcpu-2gb" # Menor tamanho para economizar custos
  node_count         = 1             # Apenas um nó em desenvolvimento
  kubernetes_version = "1.27"

  # Não é necessário criar pool crítico em desenvolvimento
  create_critical_pool = false

  # Integrar com registry apenas se especificado
  create_registry_integration = var.create_registry_integration
  registry_name               = var.registry_name

  # Alertas básicos
  alert_emails = var.alert_emails

  tags = ["dev", "terraform-managed"]

  depends_on = [module.network]
}

# Módulo de monitoramento de custos
module "cost_monitor" {
  source = "../../../modules/cost_monitor/digital-ocean"

  project_name         = var.project_name
  environment          = var.environment
  alert_emails         = var.alert_emails
  slack_channel        = var.slack_channel
  slack_webhook_url    = var.slack_webhook_url
  budget_threshold     = 5  # Limite diário baixo para ambiente dev
  monthly_budget_limit = 50 # Limite mensal baixo para ambiente dev

  # Ativar detecção de desperdício para controle de custos
  enable_waste_detection = true

  tags = ["dev", "terraform-managed", "cost-monitor"]
}