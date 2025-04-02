/**
 * # Módulo de Load Balancing
 *
 * Este módulo fornece uma interface genérica para configuração de load balancers
 * em múltiplos provedores de nuvem, incluindo Digital Ocean, AWS, GCP e Azure.
 * Dependendo do provedor especificado, o módulo chama a implementação específica
 * mantendo uma interface de entrada e saída padronizada.
 */

locals {
  is_digitalocean = var.cloud_provider == "digitalocean"
  is_aws = var.cloud_provider == "aws"
  is_gcp = var.cloud_provider == "gcp"
  is_azure = var.cloud_provider == "azure"
}

# Load Balancer para Digital Ocean
module "digitalocean_lb" {
  source = "../digital-ocean"
  
  # Só cria recursos se o provedor for Digital Ocean
  count = local.is_digitalocean ? 1 : 0
  
  name = var.name
  region = var.region
  algorithm = var.algorithm
  forwarding_rules = var.forwarding_rules
  healthcheck = var.healthcheck
  droplet_ids = var.target_nodes
  vpc_uuid = var.vpc_id
  redirect_http_to_https = var.redirect_http_to_https
  enable_proxy_protocol = var.enable_proxy_protocol
  enable_backend_keepalive = var.enable_backend_keepalive
  tags = var.tags
}

# Load Balancer para AWS
module "aws_lb" {
  source = "../aws"
  
  # Só cria recursos se o provedor for AWS
  count = local.is_aws ? 1 : 0
  
  name = var.name
  vpc_id = var.vpc_id
  subnets = var.subnets
  security_groups = var.security_groups
  internal = var.internal
  target_port = var.target_port
  target_protocol = var.target_protocol
  listener_port = var.listener_port
  listener_protocol = var.listener_protocol
  health_check_path = var.health_check_path
  health_check_port = var.health_check_port
  health_check_protocol = var.health_check_protocol
  health_check_timeout = var.health_check_timeout
  health_check_interval = var.health_check_interval
  health_check_healthy_threshold = var.health_check_healthy_threshold
  health_check_unhealthy_threshold = var.health_check_unhealthy_threshold
  target_ids = var.target_nodes
  certificate_arn = var.certificate_arn
  tags = var.tags
}

# Load Balancer para GCP
module "gcp_lb" {
  source = "../gcp"
  
  # Só cria recursos se o provedor for GCP
  count = local.is_gcp ? 1 : 0
  
  name = var.name
  project = var.project
  network = var.network
  subnetwork = var.subnetwork
  region = var.region
  target_tags = var.target_tags
  backend_services = var.backend_services
  health_check = var.health_check_config
  ssl = var.ssl
  enable_cdn = var.enable_cdn
  target_instances = var.target_nodes
  target_port = var.target_port
  certificate = var.certificate
  private_key = var.private_key
  domains = var.domains
  timeout_sec = var.timeout_sec
}

# Load Balancer para Azure
module "azure_lb" {
  source = "../azure"
  
  # Só cria recursos se o provedor for Azure
  count = local.is_azure ? 1 : 0
  
  name                = var.name
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = var.sku
  allocation_method   = var.allocation_method
  subnet_id           = var.subnet_id
  frontend_port       = var.frontend_port
  backend_port        = var.backend_port
  protocol            = var.protocol
  enable_floating_ip  = var.enable_floating_ip
  idle_timeout_in_minutes = var.idle_timeout_in_minutes
  probe_protocol      = var.probe_protocol
  probe_interval      = var.probe_interval
  probe_port          = var.probe_port
  probe_path          = var.probe_path
  target_vm_ids       = var.target_nodes
  certificate         = var.certificate
  certificate_password = var.certificate_password
  tags                = var.tags
}
