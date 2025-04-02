/**
* Arquivo de outputs para o módulo abstrato de Load Balancing.
* Define saídas unificadas independentemente do provedor utilizado.
*
* Autores:
* - Equipe de Infraestrutura Cirebox
*
* Última atualização: 2023
*/

# Mapeia os outputs de acordo com o provedor selecionado
locals {
  outputs = {
    aws = {
      load_balancer_id        = module.aws[0].load_balancer_id
      load_balancer_arn       = module.aws[0].load_balancer_arn
      load_balancer_dns_name  = module.aws[0].load_balancer_dns_name
      load_balancer_zone_id   = module.aws[0].load_balancer_zone_id
      load_balancer_ip        = null # AWS utiliza DNS em vez de IP fixo
      http_listener_arn       = module.aws[0].http_listener_arn
      https_listener_arn      = module.aws[0].https_listener_arn
      target_group_arn        = module.aws[0].target_group_arn
      security_group_id       = module.aws[0].security_group_id
    }
    digital-ocean = {
      load_balancer_id        = module.digital-ocean[0].load_balancer_id
      load_balancer_arn       = null # DO não possui ARN
      load_balancer_dns_name  = module.digital-ocean[0].load_balancer_hostname
      load_balancer_zone_id   = null # DO não possui zone_id
      load_balancer_ip        = module.digital-ocean[0].load_balancer_ip
      http_listener_arn       = null # DO não possui ARNs separados para listeners
      https_listener_arn      = null
      target_group_arn        = null # DO não possui target groups separados
      security_group_id       = null # DO usa regras de firewall separadamente
    }
    gcp = {
      load_balancer_id        = module.gcp[0].load_balancer_id
      load_balancer_arn       = null # GCP não possui ARN
      load_balancer_dns_name  = module.gcp[0].load_balancer_dns_name
      load_balancer_zone_id   = null # GCP não possui zone_id no mesmo formato da AWS
      load_balancer_ip        = module.gcp[0].load_balancer_ip
      http_listener_arn       = null # GCP não possui ARNs
      https_listener_arn      = null
      target_group_arn        = null # GCP usa backend services
      security_group_id       = null # GCP usa regras de firewall separadamente
    }
    azure = {
      load_balancer_id        = module.azure[0].load_balancer_id
      load_balancer_arn       = null # Azure não possui ARN
      load_balancer_dns_name  = module.azure[0].load_balancer_dns_name
      load_balancer_zone_id   = null # Azure não possui zone_id no mesmo formato da AWS
      load_balancer_ip        = module.azure[0].load_balancer_ip
      http_listener_arn       = null # Azure não possui ARNs
      https_listener_arn      = null
      target_group_arn        = null # Azure usa backend pools
      security_group_id       = module.azure[0].network_security_group_id
    }
  }
}

# Outputs unificados
output "id" {
  description = "ID único do balanceador de carga"
  value       = local.outputs[var.provider_name].load_balancer_id
}

output "arn" {
  description = "ARN (Amazon Resource Name) do balanceador de carga (disponível apenas para AWS)"
  value       = local.outputs[var.provider_name].load_balancer_arn
}

output "dns_name" {
  description = "Nome DNS do balanceador de carga"
  value       = local.outputs[var.provider_name].load_balancer_dns_name
}

output "zone_id" {
  description = "Zone ID do balanceador de carga (disponível apenas para AWS)"
  value       = local.outputs[var.provider_name].load_balancer_zone_id
}

output "ip_address" {
  description = "Endereço IP do balanceador de carga (nem todos os provedores fornecem IPs fixos)"
  value       = local.outputs[var.provider_name].load_balancer_ip
}

output "http_listener_arn" {
  description = "ARN do listener HTTP (disponível apenas para AWS)"
  value       = local.outputs[var.provider_name].http_listener_arn
}

output "https_listener_arn" {
  description = "ARN do listener HTTPS (disponível apenas para AWS)"
  value       = local.outputs[var.provider_name].https_listener_arn
}

output "target_group_arn" {
  description = "ARN do grupo de destino (disponível apenas para AWS)"
  value       = local.outputs[var.provider_name].target_group_arn
}

output "security_group_id" {
  description = "ID do grupo de segurança associado ao balanceador (disponível para AWS e Azure)"
  value       = local.outputs[var.provider_name].security_group_id
}

# Output para informação completa do balanceador
output "load_balancer" {
  description = "Todos os detalhes do balanceador de carga"
  value       = local.outputs[var.provider_name]
}

# Saída de estado operacional
output "status" {
  description = "Estado operacional do balanceador de carga"
  value = {
    aws           = var.provider_name == "aws" ? "active" : null
    digital-ocean = var.provider_name == "digital-ocean" ? "active" : null
    gcp           = var.provider_name == "gcp" ? "active" : null
    azure         = var.provider_name == "azure" ? "active" : null
  }
}

# Output com informações para depuração
output "debug_info" {
  description = "Informações para depuração do balanceador de carga"
  value = {
    provider = var.provider_name
    enabled  = var.enabled
    region   = var.region
  }
}

