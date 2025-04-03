/**
 * Módulo de Load Balancer para Digital Ocean
 * 
 * Este módulo implementa um Load Balancer gerenciado no Digital Ocean
 * com suporte a HTTP/HTTPS e configurações de health check.
 * 
 * Foi projetado para ser modular e facilitar a implementação de 
 * variantes para outros provedores de nuvem.
 */

# Load Balancer Principal
resource "digitalocean_loadbalancer" "main" {
  name     = "${var.project_name}-${var.environment}-lb"
  region   = var.region
  vpc_uuid = var.vpc_id

  # Ajusta o tamanho do load balancer conforme o ambiente
  # Redução de custos em ambientes não-produtivos
  size = var.environment == "prod" ? var.lb_size_prod : var.lb_size_non_prod

  # Regra de encaminhamento HTTP padrão
  forwarding_rule {
    entry_port     = 80
    entry_protocol = "http"

    target_port     = var.app_port
    target_protocol = "http"
  }

  # Regra de encaminhamento HTTPS (opcional)
  dynamic "forwarding_rule" {
    for_each = var.enable_https ? [1] : []
    content {
      entry_port      = 443
      entry_protocol  = "https"
      target_port     = var.app_port
      target_protocol = "http"
      certificate_id  = var.certificate_id
    }
  }

  # Configuração de health check
  healthcheck {
    port                     = var.healthcheck_port
    protocol                 = var.healthcheck_protocol
    path                     = var.healthcheck_path
    check_interval_seconds   = var.healthcheck_interval
    response_timeout_seconds = var.healthcheck_timeout
    unhealthy_threshold      = var.healthcheck_unhealthy_threshold
    healthy_threshold        = var.healthcheck_healthy_threshold
  }

  # Configurações avançadas
  enable_backend_keepalive = var.environment == "prod" ? true : false
  enable_proxy_protocol    = var.enable_proxy_protocol

  # Opções de redirecionamento
  redirect_http_to_https = var.enable_https && var.redirect_http_to_https

  # Gerenciamento de ciclo de vida do recurso
  lifecycle {
    create_before_destroy = true
  }
}

# DNS Registros A para o Load Balancer (opcional)
resource "digitalocean_record" "a_record" {
  count  = var.create_dns_record && var.domain_name != "" ? 1 : 0
  domain = var.domain_name
  type   = "A"
  name   = var.environment == "prod" ? "@" : var.environment
  value  = digitalocean_loadbalancer.main.ip
  ttl    = var.dns_ttl
}

# DNS Registro CNAME para www (opcional para produção)
resource "digitalocean_record" "cname_www" {
  count  = var.create_dns_record && var.domain_name != "" && var.environment == "prod" ? 1 : 0
  domain = var.domain_name
  type   = "CNAME"
  name   = "www"
  value  = "@"
  ttl    = var.dns_ttl
}

# Registros AAAA para IPv6 (quando habilitado)
resource "digitalocean_record" "aaaa_records" {
  count  = var.create_dns_record && var.domain_name != "" && var.enable_ipv6 ? 1 : 0
  domain = var.domain_name
  type   = "AAAA"
  name   = var.environment == "prod" ? "@" : var.environment
  value  = digitalocean_loadbalancer.main.ipv6
  ttl    = var.dns_ttl
}

