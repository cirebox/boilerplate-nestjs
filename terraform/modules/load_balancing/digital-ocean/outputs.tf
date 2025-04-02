/**
 * Arquivo de saídas para o módulo de load balancing no Digital Ocean
 * Este arquivo define todas as saídas úteis que o módulo pode fornecer para outros módulos ou para o ambiente principal
 */

output "load_balancer_id" {
  description = "O ID único do load balancer criado no Digital Ocean"
  value       = digitalocean_loadbalancer.main.id
}

output "load_balancer_ip" {
  description = "O endereço IP do load balancer"
  value       = digitalocean_loadbalancer.main.ip
}

output "load_balancer_status" {
  description = "O status atual do load balancer (active, erro, etc.)"
  value       = digitalocean_loadbalancer.main.status
}

output "load_balancer_hostname" {
  description = "O nome do host do load balancer, útil para configuração de DNS"
  value       = digitalocean_loadbalancer.main.hostname
}

output "load_balancer_http_idle_timeout_seconds" {
  description = "O tempo máximo, em segundos, que uma conexão pode permanecer inativa"
  value       = digitalocean_loadbalancer.main.http_idle_timeout_seconds
}

output "load_balancer_droplet_ids" {
  description = "Lista de IDs dos droplets conectados ao load balancer"
  value       = digitalocean_loadbalancer.main.droplet_ids
}

output "load_balancer_region" {
  description = "A região onde o load balancer está implantado"
  value       = digitalocean_loadbalancer.main.region
}

output "forwarding_rules" {
  description = "Configuração das regras de encaminhamento do load balancer"
  value       = digitalocean_loadbalancer.main.forwarding_rule
}

output "healthcheck_configuration" {
  description = "Configuração dos health checks do load balancer"
  value       = digitalocean_loadbalancer.main.healthcheck
}

output "sticky_sessions_configuration" {
  description = "Configuração das sessões persistentes do load balancer, se habilitadas"
  value       = digitalocean_loadbalancer.main.sticky_sessions
}

output "redirect_http_to_https" {
  description = "Indica se o redirecionamento de HTTP para HTTPS está habilitado"
  value       = digitalocean_loadbalancer.main.redirect_http_to_https
}

output "load_balancer_urn" {
  description = "O URN (Uniform Resource Name) do load balancer para integração com outros serviços"
  value       = digitalocean_loadbalancer.main.urn
}

output "vpc_uuid" {
  description = "O UUID da VPC na qual o load balancer está implantado"
  value       = digitalocean_loadbalancer.main.vpc_uuid
}

output "enable_proxy_protocol" {
  description = "Indica se o protocolo proxy está habilitado para este load balancer"
  value       = digitalocean_loadbalancer.main.enable_proxy_protocol
}

output "enable_backend_keepalive" {
  description = "Indica se o keepalive de backend está habilitado para este load balancer"
  value       = digitalocean_loadbalancer.main.enable_backend_keepalive
}

output "load_balancer_name" {
  description = "O nome do load balancer conforme definido na configuração"
  value       = digitalocean_loadbalancer.main.name
}

output "load_balancer_algorithm" {
  description = "O algoritmo utilizado pelo load balancer para distribuir o tráfego"
  value       = digitalocean_loadbalancer.main.algorithm
}

