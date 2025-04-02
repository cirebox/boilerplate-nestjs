# =========================================================
# Outputs do Módulo de Load Balancing
# =========================================================

output "load_balancer_id" {
  description = "ID único do load balancer criado, independente do provedor de nuvem"
  value       = local.selected_lb_outputs.load_balancer_id
}

output "load_balancer_ip" {
  description = "Endereço IP do load balancer criado"
  value       = local.selected_lb_outputs.load_balancer_ip
}

output "load_balancer_hostname" {
  description = "Nome de host (FQDN) do load balancer criado, se disponível"
  value       = local.selected_lb_outputs.load_balancer_hostname
}

output "load_balancer_status" {
  description = "Status atual do load balancer (ativo, em criação, etc.)"
  value       = local.selected_lb_outputs.load_balancer_status
}

output "http_port" {
  description = "Porta HTTP configurada no load balancer"
  value       = local.selected_lb_outputs.http_port
}

output "https_port" {
  description = "Porta HTTPS configurada no load balancer, se habilitada"
  value       = local.selected_lb_outputs.https_port
}

output "protocol" {
  description = "Protocolo(s) suportado(s) pelo load balancer (HTTP, HTTPS, TCP)"
  value       = local.selected_lb_outputs.protocol
}

output "tls_certificate_id" {
  description = "ID do certificado TLS associado ao load balancer, se habilitado HTTPS"
  value       = local.selected_lb_outputs.tls_certificate_id
}

output "health_check_path" {
  description = "Caminho configurado para health check dos serviços"
  value       = local.selected_lb_outputs.health_check_path
}

output "target_port" {
  description = "Porta de destino para qual o tráfego é encaminhado"
  value       = local.selected_lb_outputs.target_port
}

output "target_protocol" {
  description = "Protocolo utilizado para comunicação com os alvos do load balancer"
  value       = local.selected_lb_outputs.target_protocol
}

output "region" {
  description = "Região onde o load balancer foi provisionado"
  value       = local.selected_lb_outputs.region
}

output "tags" {
  description = "Tags associadas ao load balancer"
  value       = local.selected_lb_outputs.tags
}

locals {
  # Configuração para selecionar outputs com base no provedor escolhido
  selected_lb_outputs = {
    "digitalocean" = var.cloud_provider == "digitalocean" ? module.do_lb[0] : null
    "aws"          = var.cloud_provider == "aws" ? module.aws_lb[0] : null
    "gcp"          = var.cloud_provider == "gcp" ? module.gcp_lb[0] : null
    "azure"        = var.cloud_provider == "azure" ? module.azure_lb[0] : null
  }[var.cloud_provider]
}

