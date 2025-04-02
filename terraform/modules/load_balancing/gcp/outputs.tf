/**
 * Copyright 2023 Cirebox
 *
 * Outputs para o módulo de Load Balancing do Google Cloud Platform
 */

output "load_balancer_id" {
  description = "O ID único do Load Balancer no GCP"
  value       = var.enable_https ? google_compute_global_forwarding_rule.https[0].id : google_compute_global_forwarding_rule.http[0].id
}

output "load_balancer_name" {
  description = "O nome do Load Balancer"
  value       = var.enable_https ? google_compute_global_forwarding_rule.https[0].name : google_compute_global_forwarding_rule.http[0].name
}

output "load_balancer_self_link" {
  description = "O link de referência do Load Balancer no GCP"
  value       = var.enable_https ? google_compute_global_forwarding_rule.https[0].self_link : google_compute_global_forwarding_rule.http[0].self_link
}

output "load_balancer_ip_address" {
  description = "O endereço IP público do Load Balancer"
  value       = google_compute_global_address.main.address
}

output "backend_service_id" {
  description = "O ID do serviço de backend associado ao Load Balancer"
  value       = google_compute_backend_service.main.id
}

output "backend_service_self_link" {
  description = "O link de referência do serviço de backend"
  value       = google_compute_backend_service.main.self_link
}

output "health_check_id" {
  description = "O ID do health check utilizado pelo Load Balancer"
  value       = google_compute_health_check.main.id
}

output "health_check_self_link" {
  description = "O link de referência do health check"
  value       = google_compute_health_check.main.self_link
}

output "url_map_id" {
  description = "O ID do mapa de URL utilizado para roteamento"
  value       = google_compute_url_map.main.id
}

output "url_map_self_link" {
  description = "O link de referência do mapa de URL"
  value       = google_compute_url_map.main.self_link
}

output "target_proxy_id" {
  description = "O ID do proxy de destino (HTTP ou HTTPS)"
  value       = var.enable_https ? google_compute_target_https_proxy.main[0].id : google_compute_target_http_proxy.main[0].id
}

output "target_proxy_self_link" {
  description = "O link de referência do proxy de destino"
  value       = var.enable_https ? google_compute_target_https_proxy.main[0].self_link : google_compute_target_http_proxy.main[0].self_link
}

output "ssl_certificates" {
  description = "Lista de certificados SSL associados ao Load Balancer (se HTTPS estiver habilitado)"
  value       = var.enable_https ? google_compute_target_https_proxy.main[0].ssl_certificates : null
  sensitive   = true
}

output "load_balancer_creation_timestamp" {
  description = "Timestamp de criação do Load Balancer"
  value       = var.enable_https ? google_compute_global_forwarding_rule.https[0].creation_timestamp : google_compute_global_forwarding_rule.http[0].creation_timestamp
}

output "network_tier" {
  description = "Tier de rede utilizado pelo Load Balancer (PREMIUM ou STANDARD)"
  value       = "PREMIUM" # Global forwarding rules usam sempre PREMIUM tier
}

output "load_balancing_scheme" {
  description = "Esquema de balanceamento de carga utilizado (EXTERNAL, INTERNAL, etc.)"
  value       = "EXTERNAL" # Definido como EXTERNAL no recurso
}

output "port_range" {
  description = "Intervalo de portas configurado no Load Balancer"
  value       = var.enable_https ? google_compute_global_forwarding_rule.https[0].port_range : google_compute_global_forwarding_rule.http[0].port_range
}

