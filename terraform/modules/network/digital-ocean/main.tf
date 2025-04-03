# Módulo de rede para Digital Ocean
# Este módulo provisiona uma VPC e recursos de rede relacionados na Digital Ocean

# O bloco terraform com required_providers foi removido, pois agora as versões dos providers
# são gerenciadas centralmente no arquivo versions.tf na raiz do diretório terraform

# Criar VPC para isolar recursos
resource "digitalocean_vpc" "main" {
  name        = "${var.project_name}-${var.environment}-vpc"
  region      = var.region
  ip_range    = var.vpc_cidr
  description = "VPC para o projeto ${var.project_name} no ambiente ${var.environment}"

  # Removidos argumentos não suportados:
  # ip_range_v6 e tags
}

# Criar um projeto para organizar recursos e facilitar controle de custos
resource "digitalocean_project" "main" {
  name        = "${var.project_name}-${var.environment}"
  description = "Projeto para ${var.project_name} no ambiente ${var.environment}"
  purpose     = "Web Application"
  environment = var.environment == "prod" ? "Production" : var.environment == "staging" ? "Staging" : "Development"
}

# Criar um Firewall para controlar acesso à rede
resource "digitalocean_firewall" "web" {
  name = "${var.project_name}-${var.environment}-firewall-web"

  tags = concat(
    ["${var.project_name}", "${var.environment}", "web", "terraform-managed"],
    var.additional_tags
  )

  # Permitir tráfego HTTP(S)
  inbound_rule {
    protocol         = "tcp"
    port_range       = "80"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }

  inbound_rule {
    protocol         = "tcp"
    port_range       = "443"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }

  # Permitir SSH apenas de IPs específicos (opcional)
  dynamic "inbound_rule" {
    for_each = length(var.ssh_source_addresses) > 0 ? [1] : []
    content {
      protocol         = "tcp"
      port_range       = "22"
      source_addresses = var.ssh_source_addresses
    }
  }

  # Permitir todo tráfego interno na VPC
  inbound_rule {
    protocol         = "tcp"
    port_range       = "1-65535"
    source_addresses = [var.vpc_cidr]
  }

  inbound_rule {
    protocol         = "udp"
    port_range       = "1-65535"
    source_addresses = [var.vpc_cidr]
  }

  inbound_rule {
    protocol         = "icmp"
    source_addresses = [var.vpc_cidr]
  }

  # Permitir todo tráfego de saída
  outbound_rule {
    protocol              = "tcp"
    port_range            = "1-65535"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }

  outbound_rule {
    protocol              = "udp"
    port_range            = "1-65535"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }

  outbound_rule {
    protocol              = "icmp"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }
}

# Firewall específico para bancos de dados
resource "digitalocean_firewall" "database" {
  name = "${var.project_name}-${var.environment}-firewall-db"

  tags = concat(
    ["${var.project_name}", "${var.environment}", "database", "terraform-managed"],
    var.additional_tags
  )

  # Permitir acesso ao banco de dados apenas da VPC
  inbound_rule {
    protocol         = "tcp"
    port_range       = "5432" # PostgreSQL
    source_addresses = [var.vpc_cidr]
  }

  inbound_rule {
    protocol         = "tcp"
    port_range       = "3306" # MySQL
    source_addresses = [var.vpc_cidr]
  }

  # Permitir todo tráfego de saída
  outbound_rule {
    protocol              = "tcp"
    port_range            = "1-65535"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }

  outbound_rule {
    protocol              = "udp"
    port_range            = "1-65535"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }
}

# Load Balancer (opcional - criado apenas em ambientes que necessitam)
resource "digitalocean_loadbalancer" "public" {
  count    = var.create_loadbalancer ? 1 : 0
  name     = "${var.project_name}-${var.environment}-lb"
  region   = var.region
  vpc_uuid = digitalocean_vpc.main.id

  size = var.environment == "prod" ? "lb-small" : "lb-nano"

  # Removido o argumento tags que não é suportado

  # Configuração padrão para HTTP
  forwarding_rule {
    entry_port     = 80
    entry_protocol = "http"

    target_port     = 80
    target_protocol = "http"
  }

  # Preparado para HTTPS (requer certificado)
  dynamic "forwarding_rule" {
    for_each = var.enable_https ? [1] : []
    content {
      entry_port      = 443
      entry_protocol  = "https"
      target_port     = 80
      target_protocol = "http"
      certificate_id  = var.certificate_id
    }
  }

  # Check de saúde
  healthcheck {
    port     = 80
    protocol = "http"
    path     = "/health"
  }

  # Controle de custos: Desabilitar balanceador de carga redundante
  enable_backend_keepalive = var.environment == "prod" ? true : false
  enable_proxy_protocol    = false
}

# Recursos de domínio DNS (opcional)
resource "digitalocean_domain" "main" {
  count = var.create_domain ? 1 : 0
  name  = var.domain_name
}

# Registros DNS A para o Load Balancer
resource "digitalocean_record" "a_record" {
  count  = var.create_domain && var.create_loadbalancer ? 1 : 0
  domain = digitalocean_domain.main[0].name
  type   = "A"
  name   = var.environment == "prod" ? "@" : var.environment
  value  = digitalocean_loadbalancer.public[0].ip
  ttl    = 3600
}

# Registro CNAME para www
resource "digitalocean_record" "cname_www" {
  count  = var.create_domain && var.create_loadbalancer && var.environment == "prod" ? 1 : 0
  domain = digitalocean_domain.main[0].name
  type   = "CNAME"
  name   = "www"
  value  = "@"
  ttl    = 3600
}

# Registros MX para email (opcional)
resource "digitalocean_record" "mx_records" {
  count    = var.create_domain && var.configure_email ? length(var.mx_records) : 0
  domain   = digitalocean_domain.main[0].name
  type     = "MX"
  name     = "@"
  value    = var.mx_records[count.index].value
  priority = var.mx_records[count.index].priority
  ttl      = 3600
}

# Registros TXT para verificações de domínio e SPF (opcional)
resource "digitalocean_record" "txt_records" {
  count  = var.create_domain && length(var.txt_records) > 0 ? length(var.txt_records) : 0
  domain = digitalocean_domain.main[0].name
  type   = "TXT"
  name   = var.txt_records[count.index].name
  value  = var.txt_records[count.index].value
  ttl    = 3600
}

# Registros AAAA para IPv6 (quando habilitado)
resource "digitalocean_record" "aaaa_records" {
  count  = var.create_domain && var.create_loadbalancer && var.enable_ipv6 ? 1 : 0
  domain = digitalocean_domain.main[0].name
  type   = "AAAA"
  name   = var.environment == "prod" ? "@" : var.environment
  value  = digitalocean_loadbalancer.public[0].ipv6
  ttl    = 3600
}