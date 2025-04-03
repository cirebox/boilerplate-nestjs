/**
 * # Módulo de Load Balancing para GCP
 *
 * Este módulo implementa um Load Balancer HTTP/HTTPS global no Google Cloud Platform
 * com suporte a múltiplos backends, health checks e configurações de segurança.
 */

# O bloco terraform com required_providers foi removido, pois agora as versões dos providers
# são gerenciadas centralmente no arquivo versions.tf na raiz do diretório terraform

# Reservar um endereço IP externo para o load balancer
resource "google_compute_global_address" "main" {
  name         = var.name
  description  = "Endereço IP global para ${var.name}"
  address_type = "EXTERNAL"
  ip_version   = var.enable_ipv6 ? "IPV6" : "IPV4"
}

# Health check para verificar a integridade dos backends
resource "google_compute_health_check" "main" {
  name                = "${var.name}-health-check"
  description         = "Health check para ${var.name}"
  timeout_sec         = var.health_check_timeout_sec
  check_interval_sec  = var.health_check_interval_sec
  healthy_threshold   = var.health_check_healthy_threshold
  unhealthy_threshold = var.health_check_unhealthy_threshold

  http_health_check {
    port               = var.health_check_port
    port_specification = "USE_FIXED_PORT"
    request_path       = var.health_check_request_path
    host               = var.health_check_host
  }
}

# Backend service para servir o tráfego
resource "google_compute_backend_service" "main" {
  name                  = "${var.name}-backend"
  description           = "Backend service para ${var.name}"
  protocol              = "HTTP"
  port_name             = var.backend_port_name
  timeout_sec           = var.backend_timeout_sec
  health_checks         = [google_compute_health_check.main.id]
  load_balancing_scheme = "EXTERNAL"
  enable_cdn            = var.enable_cdn

  # Se o recurso de backend já estiver definido, use-o, caso contrário, crie um
  dynamic "backend" {
    for_each = var.backends
    content {
      group           = backend.value["group"]
      balancing_mode  = backend.value["balancing_mode"]
      capacity_scaler = lookup(backend.value, "capacity_scaler", 1.0)
    }
  }

  # Configurações de segurança (opcional)
  security_policy = var.security_policy_name != null ? var.security_policy_name : null

  # Configurações de CDN (opcional)
  dynamic "cdn_policy" {
    for_each = var.enable_cdn ? [1] : []
    content {
      cache_mode                   = var.cdn_cache_mode
      signed_url_cache_max_age_sec = var.cdn_signed_url_cache_max_age_sec
      default_ttl                  = var.cdn_default_ttl
      client_ttl                   = var.cdn_client_ttl
      max_ttl                      = var.cdn_max_ttl
      negative_caching             = var.cdn_negative_caching
    }
  }
}

# URL Map para rotear o tráfego
resource "google_compute_url_map" "main" {
  name            = "${var.name}-url-map"
  description     = "URL map para ${var.name}"
  default_service = google_compute_backend_service.main.id

  # Regras de host para diferentes serviços (opcional)
  dynamic "host_rule" {
    for_each = var.host_rules
    content {
      hosts        = host_rule.value["hosts"]
      path_matcher = host_rule.value["path_matcher"]
    }
  }

  # Path matchers para diferentes regras de host (opcional)
  dynamic "path_matcher" {
    for_each = var.path_matchers
    content {
      name            = path_matcher.value["name"]
      default_service = path_matcher.value["default_service"] != null ? path_matcher.value["default_service"] : google_compute_backend_service.main.id

      dynamic "path_rule" {
        for_each = lookup(path_matcher.value, "path_rules", [])
        content {
          paths   = path_rule.value["paths"]
          service = path_rule.value["service"]
        }
      }
    }
  }
}

# Proxy HTTP para o tráfego não-SSL
resource "google_compute_target_http_proxy" "main" {
  count       = var.enable_http ? 1 : 0
  name        = "${var.name}-http-proxy"
  description = "Target HTTP Proxy para ${var.name}"
  url_map     = google_compute_url_map.main.id
}

# Proxy HTTPS para o tráfego SSL
resource "google_compute_target_https_proxy" "main" {
  count            = var.enable_https ? 1 : 0
  name             = "${var.name}-https-proxy"
  description      = "Target HTTPS Proxy para ${var.name}"
  url_map          = google_compute_url_map.main.id
  ssl_certificates = var.ssl_certificates
  quic_override    = var.quic_override
  ssl_policy       = var.ssl_policy
}

# Regra de encaminhamento para HTTP
resource "google_compute_global_forwarding_rule" "http" {
  count                 = var.enable_http ? 1 : 0
  name                  = "${var.name}-http-rule"
  description           = "Regra de encaminhamento HTTP para ${var.name}"
  target                = google_compute_target_http_proxy.main[0].id
  ip_address            = google_compute_global_address.main.address
  port_range            = "80"
  load_balancing_scheme = "EXTERNAL"
}

# Regra de encaminhamento para HTTPS
resource "google_compute_global_forwarding_rule" "https" {
  count                 = var.enable_https ? 1 : 0
  name                  = "${var.name}-https-rule"
  description           = "Regra de encaminhamento HTTPS para ${var.name}"
  target                = google_compute_target_https_proxy.main[0].id
  ip_address            = google_compute_global_address.main.address
  port_range            = "443"
  load_balancing_scheme = "EXTERNAL"
}

# Firewall para permitir acesso do health check para os backends
resource "google_compute_firewall" "health_check" {
  count         = var.create_firewall_rule ? 1 : 0
  name          = "${var.name}-health-check-firewall"
  network       = var.network
  description   = "Regra de firewall para permitir health checks do GCP Load Balancer para ${var.name}"
  direction     = "INGRESS"
  source_ranges = ["130.211.0.0/22", "35.191.0.0/16"] # IPs dos health checks do Google

  allow {
    protocol = "tcp"
    ports    = [var.health_check_port]
  }

  target_tags = var.target_tags
}

