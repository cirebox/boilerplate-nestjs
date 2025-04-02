output "vpc_id" {
  description = "ID da VPC criada"
  value       = digitalocean_vpc.main.id
}

output "vpc_name" {
  description = "Nome da VPC criada"
  value       = digitalocean_vpc.main.name
}

output "vpc_cidr" {
  description = "Range de IP da VPC"
  value       = digitalocean_vpc.main.ip_range
}

output "project_id" {
  description = "ID do projeto Digital Ocean"
  value       = digitalocean_project.main.id
}

output "project_name" {
  description = "Nome do projeto Digital Ocean"
  value       = digitalocean_project.main.name
}

output "firewall_web_id" {
  description = "ID do firewall para aplicações web"
  value       = digitalocean_firewall.web.id
}

output "firewall_database_id" {
  description = "ID do firewall para bancos de dados"
  value       = digitalocean_firewall.database.id
}

output "loadbalancer_id" {
  description = "ID do load balancer (se criado)"
  value       = var.create_loadbalancer ? digitalocean_loadbalancer.public[0].id : null
}

output "loadbalancer_ip" {
  description = "Endereço IP do load balancer (se criado)"
  value       = var.create_loadbalancer ? digitalocean_loadbalancer.public[0].ip : null
}

output "estimated_monthly_cost" {
  description = "Estimativa de custos mensais da infraestrutura de rede"
  value = {
    vpc = "Gratuito - VPCs no Digital Ocean não têm custo"
    load_balancer = var.create_loadbalancer ? {
      type = var.environment == "prod" ? "lb-small" : "lb-nano"
      cost = var.environment == "prod" ? "$12/mês" : "$10/mês"
    } : {
      type = "N/A"
      cost = "$0/mês"
    }
    networking = "Transferência dentro da região: Gratuita. Tráfego de saída: Primeiros 1TB/mês grátis, depois $0.01/GB"
  }
}