/**
 * Módulo de rede GCP
 * 
 * Este módulo cria uma VPC, subnets privadas e públicas,
 * e Cloud NAT para acesso à internet das instâncias privadas.
 */

# Criação da rede VPC
resource "google_compute_network" "vpc" {
  name                    = "${var.project_name}-${var.environment}-vpc"
  auto_create_subnetworks = false
  routing_mode            = "GLOBAL"
  
  # Otimização para controle de custos: desativar recursos adicionais em ambientes não-produtivos
  delete_default_routes_on_create = false
  
  description = "VPC para o projeto ${var.project_name} - ambiente ${var.environment}"
}

# Subnet pública
resource "google_compute_subnetwork" "public" {
  name          = "${var.project_name}-${var.environment}-public"
  ip_cidr_range = cidrsubnet(var.vpc_cidr, 8, 0)
  region        = var.region
  network       = google_compute_network.vpc.id
  
  # Otimização para controle de custos: desabilitando logs de fluxo em ambientes não produtivos
  dynamic "log_config" {
    for_each = var.environment == "prod" ? [1] : []
    content {
      aggregation_interval = "INTERVAL_5_MIN"
      flow_sampling        = 0.5
      metadata             = "INCLUDE_ALL_METADATA"
    }
  }
  
  # Removed invalid attribute 'secondary_ip_range'
  
  description = "Subnet pública para o projeto ${var.project_name} - ambiente ${var.environment}"
}

# Subnets privadas
resource "google_compute_subnetwork" "private" {
  name          = "${var.project_name}-${var.environment}-private"
  ip_cidr_range = cidrsubnet(var.vpc_cidr, 8, 10)
  region        = var.region
  network       = google_compute_network.vpc.id
  
  # Configuração para habilitar Google Private Access
  private_ip_google_access = true
  
  # Otimização para controle de custos: desabilitando logs de fluxo em ambientes não produtivos
  dynamic "log_config" {
    for_each = var.environment == "prod" ? [1] : []
    content {
      aggregation_interval = "INTERVAL_5_MIN"
      flow_sampling        = 0.5
      metadata             = "INCLUDE_ALL_METADATA"
    }
  }
  
  description = "Subnet privada para o projeto ${var.project_name} - ambiente ${var.environment}"
}

# Endereço IP externo para Cloud NAT (opcional)
resource "google_compute_address" "nat" {
  count   = var.create_nat_gateway ? 1 : 0
  name    = "${var.project_name}-${var.environment}-nat-ip"
  region  = var.region
  
  description = "Endereço IP externo para o Cloud NAT do projeto ${var.project_name} - ambiente ${var.environment}"
}

# Cloud Router para NAT Gateway
resource "google_compute_router" "router" {
  count   = var.create_nat_gateway ? 1 : 0
  name    = "${var.project_name}-${var.environment}-router"
  region  = var.region
  network = google_compute_network.vpc.id
  
  description = "Router para o Cloud NAT do projeto ${var.project_name} - ambiente ${var.environment}"
}

# NAT Gateway (opcional)
resource "google_compute_router_nat" "nat" {
  count                              = var.create_nat_gateway ? 1 : 0
  name                               = "${var.project_name}-${var.environment}-nat"
  router                             = google_compute_router.router[0].name
  region                             = var.region
  nat_ip_allocate_option             = "MANUAL_ONLY"
  nat_ips                            = [google_compute_address.nat[0].self_link]
  source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS"
  
  # Controle de custos: aplicar apenas à subnet privada para evitar custos desnecessários
  subnetwork {
    name                    = google_compute_subnetwork.private.id
    source_ip_ranges_to_nat = ["ALL_IP_RANGES"]
  }
  
  # Otimizações para controle de custos
  log_config {
    enable = var.environment == "prod"
    filter = var.environment == "prod" ? "ERRORS_ONLY" : "ALL"
  }
  
  # Limites para evitar custos excessivos
  tcp_established_idle_timeout_sec = 1200
  udp_idle_timeout_sec             = 30
}

# Firewall para permitir SSH interno
resource "google_compute_firewall" "allow_internal" {
  name    = "${var.project_name}-${var.environment}-allow-internal"
  network = google_compute_network.vpc.id
  
  allow {
    protocol = "tcp"
  }
  
  allow {
    protocol = "udp"
  }
  
  allow {
    protocol = "icmp"
  }
  
  source_ranges = [var.vpc_cidr]
  
  description = "Permite comunicação interna na VPC para o projeto ${var.project_name} - ambiente ${var.environment}"
}

# Firewall para permitir tráfego de saída
resource "google_compute_firewall" "allow_egress" {
  name    = "${var.project_name}-${var.environment}-allow-egress"
  network = google_compute_network.vpc.id
  
  allow {
    protocol = "tcp"
  }
  
  allow {
    protocol = "udp"
  }
  
  allow {
    protocol = "icmp"
  }
  
  direction     = "EGRESS"
  destination_ranges = ["0.0.0.0/0"]
  
  description = "Permite tráfego de saída para a internet para o projeto ${var.project_name} - ambiente ${var.environment}"
}