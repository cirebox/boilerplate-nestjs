/**
 * # Módulo de Load Balancing
 *
 * Este módulo implementa uma camada de abstração para balanceadores de carga,
 * oferecendo suporte a múltiplos provedores de nuvem: AWS, GCP, Azure e DigitalOcean.
 * A escolha do provedor é feita através da variável `provider_name`.
 *
 * ## Uso
 *
 * ```hcl
 * module "load_balancer" {
 *   source = "path/to/modules/load_balancing"
 *
 *   provider_name   = "aws"  # Opções: "aws", "gcp", "azure", "digitalocean"
 *   name            = "app-lb"
 *   environment     = "production"
 *   http_port       = 80
 *   https_port      = 443
 *   health_check    = {
 *     path         = "/health"
 *     port         = 8080
 *     protocol     = "HTTP"
 *     timeout      = 5
 *     interval     = 30
 *     healthy_threshold   = 2
 *     unhealthy_threshold = 3
 *   }
 *
 *   # Parâmetros específicos do provedor
 *   # (verifique a documentação de cada submódulo para mais detalhes)
 *   
 *   # Parâmetros AWS
 *   aws_vpc_id            = var.aws_vpc_id
 *   aws_subnet_ids        = var.aws_subnet_ids
 *   aws_certificate_arn   = var.aws_certificate_arn
 *   
 *   # Parâmetros GCP
 *   gcp_project           = var.gcp_project
 *   gcp_network           = var.gcp_network
 *   gcp_subnetwork        = var.gcp_subnetwork
 *   gcp_ssl_certificates  = var.gcp_ssl_certificates
 *   
 *   # Parâmetros Azure
 *   azure_resource_group_name = var.azure_resource_group_name
 *   azure_location            = var.azure_location
 *   azure_subnet_id           = var.azure_subnet_id
 *   azure_ssl_certificate     = var.azure_ssl_certificate
 *   
 *   # Parâmetros DigitalOcean
 *   do_region                 = var.do_region
 *   do_droplet_ids            = var.do_droplet_ids
 *   do_redirect_http_to_https = var.do_redirect_http_to_https
 * }
 * ```
 */

# O bloco terraform com required_providers foi removido, pois agora as versões dos providers
# são gerenciadas centralmente no arquivo versions.tf na raiz do diretório terraform

locals {
  providers = {
    aws          = "aws"
    gcp          = "gcp"
    azure        = "azure"
    digitalocean = "digital-ocean"
  }

  provider_path = lookup(local.providers, var.provider_name, "")

  common_tags = {
    Environment = var.environment
    ManagedBy   = "terraform"
    Name        = var.name
  }
}

# Validação do provedor selecionado
resource "null_resource" "provider_validation" {
  count = local.provider_path == "" ? 1 : 0

  provisioner "local-exec" {
    command = "echo 'Erro: Provedor inválido. Valores permitidos: aws, gcp, azure, digitalocean' && exit 1"
  }
}

# AWS Load Balancer
module "aws_load_balancer" {
  count  = var.provider_name == "aws" ? 1 : 0
  source = "./aws"

  name                       = var.name
  environment                = var.environment
  vpc_id                     = var.aws_vpc_id
  subnet_ids                 = var.aws_subnet_ids
  http_port                  = var.http_port
  https_port                 = var.https_port
  health_check               = var.health_check
  enable_deletion_protection = var.enable_deletion_protection
  certificate_arn            = var.aws_certificate_arn
  tags                       = merge(local.common_tags, var.tags)
}

# Google Cloud Platform Load Balancer
module "gcp_load_balancer" {
  count  = var.provider_name == "gcp" ? 1 : 0
  source = "./gcp"

  name             = var.name
  environment      = var.environment
  project          = var.gcp_project
  network          = var.gcp_network
  subnetwork       = var.gcp_subnetwork
  http_port        = var.http_port
  https_port       = var.https_port
  health_check     = var.health_check
  ssl_certificates = var.gcp_ssl_certificates
  tags             = merge(local.common_tags, var.tags)
}

# Azure Load Balancer
module "azure_load_balancer" {
  count  = var.provider_name == "azure" ? 1 : 0
  source = "./azure"

  name                = var.name
  environment         = var.environment
  resource_group_name = var.azure_resource_group_name
  location            = var.azure_location
  subnet_id           = var.azure_subnet_id
  http_port           = var.http_port
  https_port          = var.https_port
  health_check        = var.health_check
  ssl_certificate     = var.azure_ssl_certificate
  tags                = merge(local.common_tags, var.tags)
}

# DigitalOcean Load Balancer
module "digitalocean_load_balancer" {
  count  = var.provider_name == "digitalocean" ? 1 : 0
  source = "./digital-ocean"

  name                   = var.name
  environment            = var.environment
  region                 = var.do_region
  droplet_ids            = var.do_droplet_ids
  http_port              = var.http_port
  https_port             = var.https_port
  health_check           = var.health_check
  redirect_http_to_https = var.do_redirect_http_to_https
  tags                   = merge(local.common_tags, var.tags)
}

# Outputs são definidos com base no provedor selecionado
locals {
  load_balancer = {
    aws          = var.provider_name == "aws" ? module.aws_load_balancer[0] : null
    gcp          = var.provider_name == "gcp" ? module.gcp_load_balancer[0] : null
    azure        = var.provider_name == "azure" ? module.azure_load_balancer[0] : null
    digitalocean = var.provider_name == "digitalocean" ? module.digitalocean_load_balancer[0] : null
  }
}

