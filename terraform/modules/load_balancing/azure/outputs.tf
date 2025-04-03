/**
 * Arquivo de outputs do módulo de balanceamento de carga do Azure.
 * Contém todas as saídas necessárias para utilização do módulo em outros recursos.
 */

output "load_balancer_id" {
  description = "ID do Azure Load Balancer"
  value       = azurerm_lb.main.id
}

output "load_balancer_ip" {
  description = "Endereço IP público do load balancer"
  value       = azurerm_public_ip.main.ip_address
}

output "load_balancer_fqdn" {
  description = "FQDN do load balancer, se disponível"
  value       = azurerm_public_ip.main.fqdn
}

output "load_balancer_dns_name" {
  description = "Nome DNS do load balancer"
  value       = azurerm_public_ip.main.fqdn != "" ? azurerm_public_ip.main.fqdn : "não aplicável - IP privado"
}

output "backend_pool_id" {
  description = "ID do backend pool"
  value       = azurerm_lb_backend_address_pool.main.id
}

output "health_probe_id" {
  description = "ID da sonda de saúde (health probe)"
  value       = azurerm_lb_probe.http.id
}

output "frontend_ip_configuration_id" {
  description = "ID da configuração de IP frontend"
  value       = azurerm_lb.main.frontend_ip_configuration[0].id
}

output "network_security_rules" {
  description = "Regras de segurança de rede associadas, se aplicável"
  value       = try(azurerm_network_security_rule.lb_rules[*].name, [])
}

output "https_enabled" {
  description = "Indica se HTTPS está habilitado"
  value       = var.enable_https
}

output "application_gateway_id" {
  description = "ID do Application Gateway (se HTTPS estiver habilitado)"
  value       = var.enable_https ? try(azurerm_application_gateway.main[0].id, null) : null
}

output "ssl_certificate_name" {
  description = "Nome do certificado SSL, se configurado"
  value       = var.enable_https ? var.ssl_certificate_name : null
  sensitive   = true
}

