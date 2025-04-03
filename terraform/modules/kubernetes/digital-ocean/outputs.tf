output "cluster_id" {
  description = "ID do cluster Kubernetes"
  value       = digitalocean_kubernetes_cluster.main.id
}

output "cluster_name" {
  description = "Nome do cluster Kubernetes"
  value       = digitalocean_kubernetes_cluster.main.name
}

output "kubernetes_version" {
  description = "Versão do Kubernetes utilizada"
  value       = digitalocean_kubernetes_cluster.main.version
}

output "cluster_endpoint" {
  description = "Endpoint da API do Kubernetes"
  value       = digitalocean_kubernetes_cluster.main.endpoint
}

output "kube_config" {
  description = "Conteúdo do kubeconfig para acesso ao cluster"
  value       = digitalocean_kubernetes_cluster.main.kube_config[0].raw_config
  sensitive   = true
}

output "default_node_pool_id" {
  description = "ID do node pool padrão"
  value       = digitalocean_kubernetes_cluster.main.node_pool[0].id
}

output "default_node_pool_name" {
  description = "Nome do node pool padrão"
  value       = digitalocean_kubernetes_cluster.main.node_pool[0].name
}

output "critical_node_pool_id" {
  description = "ID do node pool crítico (se criado)"
  value       = var.environment == "prod" && var.create_critical_pool ? digitalocean_kubernetes_node_pool.critical[0].id : null
}

output "critical_node_pool_name" {
  description = "Nome do node pool crítico (se criado)"
  value       = var.environment == "prod" && var.create_critical_pool ? digitalocean_kubernetes_node_pool.critical[0].name : null
}

output "kubectl_config_command" {
  description = "Comando para configurar o kubectl com o novo cluster"
  value       = "doctl kubernetes cluster kubeconfig save ${digitalocean_kubernetes_cluster.main.id}"
}

output "registry_integration_enabled" {
  description = "Indica se a integração com registry está ativada"
  value       = var.create_registry_integration
}

output "registry_secret_name" {
  description = "Nome do secret para autenticação do registry (se habilitado)"
  value       = var.create_registry_integration ? kubernetes_secret.registry_credentials[0].metadata[0].name : null
}

# Cálculos de custo usando locals em vez de funções
locals {
  doks_node_costs = {
    "s-1vcpu-2gb"  = 12
    "s-2vcpu-2gb"  = 18
    "s-2vcpu-4gb"  = 24
    "s-4vcpu-8gb"  = 48
    "s-8vcpu-16gb" = 96
    "default"      = 18
  }

  # Cálculo de custo do node pool padrão
  default_node_cost = lookup(local.doks_node_costs, var.node_size, local.doks_node_costs["default"]) * var.node_count

  # Cálculo de custo do node pool crítico
  critical_node_cost = (var.environment == "prod" && var.create_critical_pool) ? (lookup(local.doks_node_costs, var.critical_node_size, local.doks_node_costs["default"]) * var.critical_node_count) : 0

  # Custo de alta disponibilidade
  ha_cost = var.environment == "prod" ? 60 : 0

  # Custo total
  total_cost = local.default_node_cost + local.critical_node_cost + local.ha_cost
}

output "estimated_monthly_cost" {
  description = "Estimativa de custos mensais do cluster Kubernetes"
  value = {
    node_pool_default = {
      size  = var.node_size
      count = var.node_count
      cost_per_node = var.node_size == "s-1vcpu-2gb" ? "12 USD/mês" : (
        var.node_size == "s-2vcpu-2gb" ? "18 USD/mês" : (
          var.node_size == "s-2vcpu-4gb" ? "24 USD/mês" : (
      var.node_size == "s-4vcpu-8gb" ? "48 USD/mês" : "Verificar preços DigitalOcean")))
      monthly_estimate = "${local.default_node_cost} USD/mês"
    },
    node_pool_critical = var.environment == "prod" && var.create_critical_pool ? {
      size  = var.critical_node_size
      count = var.critical_node_count
      cost_per_node = var.critical_node_size == "s-2vcpu-4gb" ? "24 USD/mês" : (
        var.critical_node_size == "s-4vcpu-8gb" ? "48 USD/mês" : (
      var.critical_node_size == "s-8vcpu-16gb" ? "96 USD/mês" : "Verificar preços DigitalOcean"))
      monthly_estimate = "${local.critical_node_cost} USD/mês"
    } : null,
    high_availability = {
      enabled         = var.environment == "prod"
      additional_cost = var.environment == "prod" ? "60 USD/mês" : "0 USD/mês"
    },
    total_estimate = "${local.total_cost} USD/mês"
  }
}

output "cost_optimization_tips" {
  description = "Dicas para otimização de custos do DOKS"
  value = [
    "1. Utilize o Kubernetes Cluster Autoscaler para ajustar o número de nós conforme a demanda",
    "2. Implemente o Horizontal Pod Autoscaler para ajustar o número de réplicas conforme a carga",
    "3. Use o tamanho de nó mais apropriado para sua workload (CPU/Memory ratio)",
    "4. Considere usar spot instances para workloads tolerantes a interrupções",
    "5. Configure políticas de escalonamento para reduzir o cluster em períodos de baixo uso",
    "6. Utilize namespaces para isolar recursos e facilitar o monitoramento de custos",
    "7. Configure requests e limits adequadamente para cada aplicação",
    "8. Use o Vertical Pod Autoscaler para otimizar as solicitações de recursos",
    "9. Considere desligar clusters de desenvolvimento quando não estiverem em uso",
    "10. Aproveite a integração com o Container Registry do Digital Ocean para reduzir custos de transferência"
  ]
}