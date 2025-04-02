/**
 * Arquivo de outputs do módulo de balanceamento de carga do Azure.
 * Contém todas as saídas necessárias para utilização do módulo em outros recursos.
 */

output "load_balancer_id" {
  description = "ID do Load Balancer criado no Azure"
  value       = azurerm_lb.main.id
}

output "load_balancer_name" {
  description = "Nome do Azure Load Balancer"
  value       = azurerm_lb.main.name
}

output "load_balancer_ip" {
  description = "Endereço IP público do Load Balancer"
  value       = azurerm_public_ip.main.ip_address
}

output "load_balancer_dns" {
  description = "Nome DNS completo do Load Balancer"
  value       = azurerm_public_ip.main.fqdn
}

output "frontend_ip_configuration_name" {
  description = "Nome da configuração de IP frontend do Load Balancer"
  value       = azurerm_lb.main.frontend_ip_configuration[0].name
}

output "backend_address_pool_id" {
  description = "ID do pool de endereços backend do Load Balancer"
  value       = azurerm_lb_backend_address_pool.main.id
}

output "backend_pool_name" {
  description = "Nome do backend pool configurado"
  value       = azurerm_lb_backend_address_pool.main.name
}

output "http_rule_name" {
  description = "Nome da regra HTTP do Load Balancer"
  value       = var.enable_http ? azurerm_lb_rule.http[0].name : null
}

output "https_rule_name" {
  description = "Nome da regra HTTPS do Load Balancer"
  value       = var.enable_https ? azurerm_lb_rule.https[0].name : null
}

output "http_listener_id" {
  description = "ID do listener HTTP configurado no balanceador"
  value       = var.enable_http ? azurerm_lb_rule.http[0].id : null
}

output "https_listener_id" {
  description = "ID do listener HTTPS configurado no balanceador (se habilitado)"
  value       = var.enable_https ? azurerm_lb_rule.https[0].id : null
}

output "health_probe_id" {
  description = "ID do health probe do Load Balancer"
  value       = azurerm_lb_probe.main.id
}

output "nat_rules" {
  description = "IDs das regras NAT configuradas, se existirem"
  value       = [for rule in azurerm_lb_nat_rule.rules : rule.id]
}

output "resource_group_name" {
  description = "Nome do grupo de recursos onde o Load Balancer foi criado"
  value       = var.resource_group_name
}

output "location" {
  description = "Região do Azure onde o Load Balancer foi criado"
  value       = var.location
}

output "tags" {
  description = "Tags aplicadas ao Load Balancer"
  value       = azurerm_lb.main.tags
}

output "load_balancer_rules" {
  description = "Lista de regras configuradas no load balancer"
  value       = concat(
    var.enable_http ? [azurerm_lb_rule.http[0].name] : [],
    var.enable_https ? [azurerm_lb_rule.https[0].name] : []
  )
}

output "diagnostic_settings" {
  description = "Configurações de diagnóstico do Load Balancer"
  value       = var.enable_diagnostics ? azurerm_monitor_diagnostic_setting.main[0].id : null
}

output "waf_policy_id" {
  description = "ID da política de Web Application Firewall associada ao Load Balancer (se habilitada)"
  value       = var.enable_waf ? azurerm_web_application_firewall_policy.main[0].id : null
}

