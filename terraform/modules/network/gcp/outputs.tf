output "vpc_id" {
  description = "ID da VPC criada"
  value       = google_compute_network.vpc.id
}

output "vpc_name" {
  description = "Nome da VPC criada"
  value       = google_compute_network.vpc.name
}

output "vpc_self_link" {
  description = "Self-link da VPC criada"
  value       = google_compute_network.vpc.self_link
}

output "public_subnet_id" {
  description = "ID da subnet pública"
  value       = google_compute_subnetwork.public.id
}

output "public_subnet_name" {
  description = "Nome da subnet pública"
  value       = google_compute_subnetwork.public.name
}

output "public_subnet_self_link" {
  description = "Self-link da subnet pública"
  value       = google_compute_subnetwork.public.self_link
}

output "private_subnet_id" {
  description = "ID da subnet privada"
  value       = google_compute_subnetwork.private.id
}

output "private_subnet_name" {
  description = "Nome da subnet privada"
  value       = google_compute_subnetwork.private.name
}

output "private_subnet_self_link" {
  description = "Self-link da subnet privada"
  value       = google_compute_subnetwork.private.self_link
}

output "nat_ip" {
  description = "Endereço IP do Cloud NAT (se criado)"
  value       = var.create_nat_gateway ? google_compute_address.nat[0].address : null
}

output "private_subnet_ids" {
  description = "Lista de IDs das subnets privadas (formato compatível com outros provedores)"
  value       = [google_compute_subnetwork.private.id]
}

output "estimated_monthly_cost" {
  description = "Estimativa de custos mensais de rede"
  value = {
    vpc = "Gratuito (não há custos para manter VPCs no GCP)"
    nat = var.create_nat_gateway ? {
      gateway_hours  = "$0.0375/hora = ~$27/mês"
      data_processed = "Depende do uso: $0.045/GB processado"
      ip_address     = "$0.004/hora = ~$3/mês por IP"
      } : {
      gateway_hours  = "$0/mês"
      data_processed = "$0/mês"
      ip_address     = "$0/mês"
    }
    network_egress = "Depende do tráfego: $0.085-$0.23/GB (varia por região)"
    logs           = var.environment == "prod" ? "Alta amostragem, custos maiores" : "Baixa amostragem para economia"
  }
}