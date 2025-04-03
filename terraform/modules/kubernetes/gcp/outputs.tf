output "cluster_name" {
  description = "Nome do cluster GKE criado"
  value       = google_container_cluster.primary.name
}

output "cluster_endpoint" {
  description = "Endpoint para acessar o API server do Kubernetes"
  value       = "https://${google_container_cluster.primary.endpoint}"
}

output "cluster_ca_certificate" {
  description = "Certificado de autoridade do cluster Kubernetes"
  value       = base64decode(google_container_cluster.primary.master_auth[0].cluster_ca_certificate)
  sensitive   = true
}

output "cluster_location" {
  description = "Localização do cluster GKE (região ou zona)"
  value       = google_container_cluster.primary.location
}

output "kubectl_config_command" {
  description = "Comando para configurar o kubectl com o novo cluster"
  value       = "gcloud container clusters get-credentials ${google_container_cluster.primary.name} --region ${google_container_cluster.primary.location} --project ${var.project_id}"
}

output "service_account_email" {
  description = "Email da conta de serviço criada para o autoscaler"
  value       = google_service_account.cluster_autoscaler.email
}

output "node_pools" {
  description = "Nomes dos node pools criados"
  value = {
    default = google_container_node_pool.default.name
    system  = var.environment == "prod" ? google_container_node_pool.system[0].name : "" # Corrigido: retorna string vazia em vez de null
  }
}

# Cálculos de custo usando locals em vez de funções
locals {
  cost_per_node_prod = {
    "e2-standard-2" = "60 USD"
    "e2-medium"     = "33 USD"
    "e2-small"      = "16 USD"
    "default"       = "75 USD"
  }

  cost_per_node_prod_value = {
    "e2-standard-2" = 60
    "e2-medium"     = 33
    "e2-small"      = 16
    "default"       = 75
  }

  cost_per_node_dev = {
    "e2-standard-2" = "18 USD"
    "e2-medium"     = "10 USD"
    "e2-small"      = "5 USD"
    "default"       = "22 USD"
  }

  cost_per_node_dev_value = {
    "e2-standard-2" = 18
    "e2-medium"     = 10
    "e2-small"      = 5
    "default"       = 22
  }

  # Lookup para obter o custo por nó em produção
  prod_cost_per_node       = lookup(local.cost_per_node_prod, var.node_instance_types[0], local.cost_per_node_prod["default"])
  prod_cost_per_node_value = lookup(local.cost_per_node_prod_value, var.node_instance_types[0], local.cost_per_node_prod_value["default"])

  # Lookup para obter o custo por nó em desenvolvimento (preemptível)
  dev_cost_per_node       = lookup(local.cost_per_node_dev, var.node_instance_types[0], local.cost_per_node_dev["default"])
  dev_cost_per_node_value = lookup(local.cost_per_node_dev_value, var.node_instance_types[0], local.cost_per_node_dev_value["default"])

  # Cálculo do custo total estimado
  estimated_cost_value = var.environment == "prod" ? (var.desired_nodes * local.prod_cost_per_node_value) : (var.desired_nodes * local.dev_cost_per_node_value)
}

output "estimated_monthly_cost" {
  description = "Estimativa de custos mensais com base nas configurações atuais"
  value = {
    cluster_management = {
      cost    = var.environment == "prod" ? "73 USD/mês (standard)" : "Gratuito (cluster Zonal)"
      details = var.environment == "prod" ? "Cluster GKE Standard" : "Cluster GKE Autopilot é cobrado somente por recursos utilizados"
    }
    node_pools = {
      default = {
        machine_type = var.node_instance_types[0]
        node_count   = var.desired_nodes
        preemptible  = var.environment != "prod"
        estimated_cost = var.environment == "prod" ? (
          "${var.desired_nodes} x ${local.prod_cost_per_node} = ${local.estimated_cost_value} USD/mês"
          ) : (
          "${var.desired_nodes} x ${local.dev_cost_per_node} (preemptível) = ${local.estimated_cost_value} USD/mês"
        )
      }
      system = var.environment == "prod" ? {
        machine_type   = "e2-small"
        node_count     = 1
        preemptible    = false
        estimated_cost = "16 USD/mês"
      } : null
    }
    networking = {
      cost = "Tráfego interno gratuito, tráfego externo: 0.085-0.23 USD/GB"
    }
    storage = {
      cost = "Depende do uso: 0.04 USD/GB/mês para PD Standard, 0.17 USD/GB/mês para PD SSD"
    }
    monitoring = {
      enabled = var.environment == "prod"
      details = var.environment == "prod" ? {
        logs    = "Primeiro 50 GB gratuito, depois 0.50 USD/GB"
        metrics = "Primeiro 150 MB gratuito, depois 0.258 USD/milhão de amostras"
        } : {
        message = "Logs e monitoramento desativados para economia de custos"
      }
    }
  }
}

output "cost_optimization_tips" {
  description = "Dicas para otimização de custos do GKE"
  value = [
    "1. Use VMs preemptivas para workloads não críticas (economia de até 70%)",
    "2. Otimize os recursos solicitados pelos pods para melhor utilização dos nós",
    "3. Use Kubernetes Cluster Autoscaler para escalar automaticamente os nós",
    "4. Implemente o Horizontal Pod Autoscaler para ajustar o número de réplicas",
    "5. Considere o uso do GKE Autopilot para ambientes de desenvolvimento",
    "6. Use o Vertical Pod Autoscaler para otimizar solicitações de recursos",
    "7. Configure escalas para zero em ambientes não produtivos fora do horário comercial",
    "8. Use node pools dedicados para workloads específicas",
    "9. Escolha tamanhos de nós otimizados para evitar desperdício",
    "10. Monitore e analise os custos regularmente usando o Cloud Billing"
  ]
}