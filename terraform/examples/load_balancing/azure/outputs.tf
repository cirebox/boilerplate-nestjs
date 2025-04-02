# Saídas do módulo de balanceamento de carga do Azure

output "load_balancer_id" {
  description = "O ID do balanceador de carga criado no Azure"
  value       = module.load_balancer.load_balancer_id
}


output "frontend_ip_configuration_name" {
  description = "O nome da configuração de IP frontend do balanceador de carga"
  value       = module.load_balancer.frontend_ip_configuration_name
}

output "http_rule_name" {
  description = "O nome da regra HTTP configurada no balanceador de carga"
  value       = module.load_balancer.http_rule_name
}

output "https_rule_name" {
  description = "O nome da regra HTTPS configurada no balanceador de carga"
  value       = module.load_balancer.https_rule_name
}

output "backend_pool_id" {
  description = "O ID do pool de backend do balanceador de carga"
  value       = module.load_balancer.backend_pool_id
}

output "health_probe_id" {
  description = "O ID da sonda de verificação de saúde do balanceador de carga"
  value       = module.load_balancer.health_probe_id
}

