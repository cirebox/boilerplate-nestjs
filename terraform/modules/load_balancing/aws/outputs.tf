/**
 * Outputs para o módulo de Load Balancing da AWS
 * Este arquivo define todas as saídas úteis do módulo de AWS Load Balancer
 * para serem utilizadas por outros módulos ou pelo módulo raiz.
 */

output "alb_id" {
  description = "O ID do Application Load Balancer criado"
  value       = aws_lb.main.id
}

output "alb_arn" {
  description = "O ARN (Amazon Resource Name) do Application Load Balancer"
  value       = aws_lb.main.arn
}

output "alb_dns_name" {
  description = "O nome DNS do Application Load Balancer, que pode ser usado para acessar a aplicação"
  value       = aws_lb.main.dns_name
}

output "alb_zone_id" {
  description = "O ID da zona do Route 53 do load balancer, útil para criar registros de alias"
  value       = aws_lb.main.zone_id
}

output "target_group_arns" {
  description = "Lista dos ARNs dos target groups criados"
  value       = [for tg in aws_lb_target_group.main : tg.arn]
}

output "target_group_names" {
  description = "Lista dos nomes dos target groups criados"
  value       = [for tg in aws_lb_target_group.main : tg.name]
}

output "http_listener_arn" {
  description = "ARN do listener HTTP, se criado"
  value       = var.enable_http ? aws_lb_listener.http[0].arn : null
}

output "https_listener_arn" {
  description = "ARN do listener HTTPS, se criado"
  value       = var.enable_https ? aws_lb_listener.https[0].arn : null
}

output "security_group_id" {
  description = "ID do grupo de segurança associado ao load balancer"
  value       = aws_security_group.alb.id
}

output "security_group_name" {
  description = "Nome do grupo de segurança associado ao load balancer"
  value       = aws_security_group.alb.name
}

output "http_enabled" {
  description = "Indica se o tráfego HTTP está habilitado no load balancer"
  value       = var.enable_http
}

output "https_enabled" {
  description = "Indica se o tráfego HTTPS está habilitado no load balancer"
  value       = var.enable_https
}

output "ssl_certificate_arn" {
  description = "ARN do certificado SSL associado ao listener HTTPS, se aplicável"
  value       = var.enable_https ? var.ssl_certificate_arn : null
}

output "health_check_path" {
  description = "Caminho usado para verificações de saúde dos serviços"
  value       = var.health_check_path
}

output "alb_full_name" {
  description = "Nome completo do Application Load Balancer, incluindo o prefixo do ambiente"
  value       = aws_lb.main.name
}

output "access_logs_bucket" {
  description = "Nome do bucket S3 onde os logs de acesso são armazenados, se habilitado"
  value       = var.enable_access_logs ? var.access_logs_bucket : null
}

output "load_balancer_type" {
  description = "Tipo do Load Balancer (application, network, gateway)"
  value       = aws_lb.main.load_balancer_type
}

output "deletion_protection_enabled" {
  description = "Indica se a proteção contra exclusão está habilitada para o load balancer"
  value       = var.enable_deletion_protection
}

output "idle_timeout" {
  description = "Tempo de inatividade configurado para as conexões do load balancer, em segundos"
  value       = var.idle_timeout
}

output "vpc_id" {
  description = "ID da VPC onde o load balancer está implantado"
  value       = var.vpc_id
}

output "subnet_ids" {
  description = "IDs das subnets onde o load balancer está implantado"
  value       = var.subnet_ids
}

