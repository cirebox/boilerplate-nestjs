# Arquivo de configuração de provedores para organizar melhor a infraestrutura

# AWS Provider
provider "aws" {
  alias   = "primary"
  region  = lookup(local.provider_config.aws, "region", "us-east-1")
  profile = lookup(local.provider_config.aws, "profile", "default")

  # Default tags para todos os recursos AWS
  default_tags {
    tags = local.common_tags
  }

  # Configurações avançadas para melhorar resiliência
  skip_metadata_api_check = lookup(local.provider_config.aws, "skip_metadata_check", true)
  skip_region_validation  = lookup(local.provider_config.aws, "skip_region_validation", false)

  assume_role {
    role_arn     = lookup(local.provider_config.aws, "assume_role_arn", null)
    session_name = "${var.project_name}-${var.environment}-terraform"
    external_id  = lookup(local.provider_config.aws, "external_id", null)
  }
}

# AWS Provider Secundário (para recursos multi-região)
provider "aws" {
  alias   = "secondary"
  region  = lookup(local.provider_config.aws, "secondary_region", "us-west-2")
  profile = lookup(local.provider_config.aws, "profile", "default")

  default_tags {
    tags = local.common_tags
  }
}

# Google Cloud Platform Provider
provider "google" {
  alias       = "primary"
  project     = lookup(local.provider_config.gcp, "project", null)
  region      = lookup(local.provider_config.gcp, "region", "us-central1")
  zone        = lookup(local.provider_config.gcp, "zone", "us-central1-a")
  credentials = lookup(local.provider_config.gcp, "credentials_file", null) != null ? file(local.provider_config.gcp.credentials_file) : null

  # Configuração para APIs específicas
  scopes = [
    "https://www.googleapis.com/auth/cloud-platform",
    "https://www.googleapis.com/auth/userinfo.email",
  ]
}

# Provider para GCP Beta Features
provider "google-beta" {
  alias       = "beta"
  project     = lookup(local.provider_config.gcp, "project", null)
  region      = lookup(local.provider_config.gcp, "region", "us-central1")
  zone        = lookup(local.provider_config.gcp, "zone", "us-central1-a")
  credentials = lookup(local.provider_config.gcp, "credentials_file", null) != null ? file(local.provider_config.gcp.credentials_file) : null
}

# DigitalOcean Provider
provider "digitalocean" {
  alias = "primary"
  token = sensitive(
    lookup(local.provider_config.digitalocean, "token", null) != null ?
    local.provider_config.digitalocean.token :
    try(trimspace(file(lookup(local.provider_config.digitalocean, "token_file", "/dev/null"))), null)
  )
  # Autenticação via variável de ambiente DIGITALOCEAN_TOKEN também é suportada
}

# Provider Docker para ambiente local
provider "docker" {
  alias = "local"
  host  = lookup(local.provider_config.local, "docker_host", "unix:///var/run/docker.sock")

  # Configurações opcionais para conexão SSH com Docker remoto
  ssh_opts = [
    "-o", "StrictHostKeyChecking=no",
    "-o", "UserKnownHostsFile=/dev/null"
  ]

  # Configurações de autenticação com registries Docker
  registry_auth {
    address  = lookup(lookup(local.provider_config.local, "docker_registry", {}), "address", "registry.hub.docker.com")
    username = lookup(lookup(local.provider_config.local, "docker_registry", {}), "username", null)
    password = lookup(lookup(local.provider_config.local, "docker_registry", {}), "password", null)
  }
}

# Provider para Kubernetes - suporte para múltiplos cluster contexts
provider "kubernetes" {
  alias = "primary"

  dynamic "exec" {
    for_each = local.active_provider == "aws" ? [1] : []
    content {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args        = ["eks", "get-token", "--cluster-name", local.cluster_name]
    }
  }

  host                   = local.k8s_host
  cluster_ca_certificate = local.k8s_ca_cert
  token                  = local.k8s_token

  # Configurações de timeout para operações k8s
}

# Variáveis locais para configuração de providers
locals {
  common_tags = merge(var.tags, {
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "Terraform"
    Provisioner = "CI/CD"
    Timestamp   = formatdate("YYYY-MM-DD-hh-mm-ss", timestamp())
  })

  # Lógica para determinar o contexto do Kubernetes baseado no provider ativo
  cluster_name = local.active_provider == "aws" ? (
    length(module.kubernetes_aws) > 0 ? module.kubernetes_aws[0].cluster_name : ""
    ) : local.active_provider == "gcp" ? (
    length(module.kubernetes_gcp) > 0 ? module.kubernetes_gcp[0].cluster_name : ""
    ) : local.active_provider == "digitalocean" ? (
    local.do_cluster_name # Usando a variável local que definimos em main.tf
  ) : ""

  # Variáveis para configuração do Kubernetes provider
  k8s_host = local.active_provider == "aws" ? (
    length(module.kubernetes_aws) > 0 ? module.kubernetes_aws[0].cluster_endpoint : ""
    ) : local.active_provider == "gcp" ? (
    length(module.kubernetes_gcp) > 0 ? module.kubernetes_gcp[0].cluster_endpoint : ""
    ) : local.active_provider == "digitalocean" ? (
    local.do_k8s_endpoint # Usando a variável local que definimos em main.tf
  ) : ""

  k8s_ca_cert = local.active_provider == "aws" ? (
    length(module.kubernetes_aws) > 0 ? base64decode(module.kubernetes_aws[0].cluster_ca_certificate) : ""
    ) : local.active_provider == "gcp" ? (
    length(module.kubernetes_gcp) > 0 ? base64decode(module.kubernetes_gcp[0].cluster_ca_certificate) : ""
    ) : local.active_provider == "digitalocean" ? (
    local.do_k8s_ca_cert # Usando a variável local que definimos em main.tf
  ) : ""

  k8s_token = local.active_provider == "aws" ? (
    length(module.kubernetes_aws) > 0 ? module.kubernetes_aws[0].cluster_token : ""
    ) : local.active_provider == "gcp" ? (
    length(module.kubernetes_gcp) > 0 ? module.kubernetes_gcp[0].cluster_token : ""
    ) : local.active_provider == "digitalocean" ? (
    local.do_k8s_token # Usando a variável local que definimos em main.tf
  ) : ""
}

# Adicionando o provider null explicitamente
provider "null" {
  # Sem configuração necessária
}