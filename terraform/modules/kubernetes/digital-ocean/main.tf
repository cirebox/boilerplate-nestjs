/**
 * Módulo de Kubernetes para Digital Ocean (DOKS)
 * 
 * Este módulo cria um cluster Kubernetes gerenciado no Digital Ocean
 * com configurações otimizadas para controle de custos.
 */

# Removida a configuração local de providers para permitir uso com count/for_each
# terraform {
#   required_providers {
#     digitalocean = {
#       source  = "digitalocean/digitalocean"
#       version = "~> 2.36"
#     }
#     kubernetes = {
#       source = "hashicorp/kubernetes"
#     }
#   }
# }

locals {
  # Usar cluster_name da variável se fornecido, caso contrário gerar um
  actual_cluster_name = var.cluster_name != null ? var.cluster_name : "${var.project_name}-${var.environment}-k8s"
  tags         = concat([var.environment, var.project_name, "k8s", "terraform"], var.tags)
}

# Cluster Kubernetes DOKS - Condicionalmente criado baseado na variável enabled
resource "digitalocean_kubernetes_cluster" "main" {
  # Criar o recurso apenas se enabled = true
  count        = var.enabled ? 1 : 0
  
  name         = local.actual_cluster_name
  region       = var.region
  version      = var.kubernetes_version
  vpc_uuid     = var.vpc_id
  auto_upgrade = var.environment == "prod"
  
  # Configuração do node pool padrão
  node_pool {
    name       = "${local.actual_cluster_name}-default-pool"
    size       = var.node_size
    node_count = var.node_count
    
    # Auto-scale configurado apenas para ambientes de produção
    auto_scale = var.environment == "prod" ? true : false
    min_nodes  = var.environment == "prod" ? var.min_nodes : null
    max_nodes  = var.environment == "prod" ? var.max_nodes : null
    
    # Controle de custos: Tags para identificar recursos e alocar custos
    tags = local.tags
  }
  
  # Configuração de HA
  ha = var.environment == "prod" ? true : false
  
  # Configuração de manutenção - horários de baixo tráfego
  maintenance_policy {
    start_time = "04:00"
    day        = "sunday"
  }
  
  # Proteção para evitar destruição acidental - usando valor fixo
  lifecycle {
    prevent_destroy = false
    ignore_changes  = [
      # Ignorar mudanças no Kubernetes version para evitar upgrades não planejados
      version
    ]
  }
}

# Node pool adicional para serviços críticos (apenas em produção)
resource "digitalocean_kubernetes_node_pool" "critical" {
  # Criado apenas se o módulo está habilitado, ambiente é produção e create_critical_pool é true
  count      = var.enabled && var.environment == "prod" && var.create_critical_pool ? 1 : 0
  
  cluster_id = digitalocean_kubernetes_cluster.main[0].id
  name       = "${local.actual_cluster_name}-critical-pool"
  size       = var.critical_node_size
  node_count = var.critical_node_count
  
  # Configuração de auto-scaling
  auto_scale = true
  min_nodes  = 1
  max_nodes  = 3
  
  # Taints para garantir que apenas cargas de trabalho críticas sejam agendadas neste pool
  taint {
    key    = "workload"
    value  = "critical"
    effect = "NoSchedule"
  }
  
  # Tags para identificação e alocação de custos
  tags = concat(local.tags, ["critical"])
}

# Permitir que o cluster acesse o Docker Registry privado do Digital Ocean
resource "digitalocean_container_registry_docker_credentials" "registry_credentials" {
  # Criado apenas se o módulo está habilitado e create_registry_integration é true
  count      = var.enabled && var.create_registry_integration ? 1 : 0
  
  registry_name = var.registry_name
  
  # Configurar para expirar após um período (maior para produção, menor para dev)
  expiry_seconds = var.environment == "prod" ? 31536000 : 2592000 # 1 ano vs 30 dias
}

# Integração com o cluster Kubernetes
resource "kubernetes_secret" "registry_credentials" {
  count = var.create_registry_integration ? 1 : 0
  
  metadata {
    name      = "docker-cfg"
    namespace = "default"
  }
  
  data = {
    ".dockerconfigjson" = digitalocean_container_registry_docker_credentials.registry_credentials[0].docker_credentials
  }
  
  type = "kubernetes.io/dockerconfigjson"
  
  depends_on = [
    digitalocean_kubernetes_cluster.main,
    digitalocean_container_registry_docker_credentials.registry_credentials
  ]
}

# Configurar métricas e monitoramento para o cluster (opcional - para controle de custos)
resource "digitalocean_monitor_alert" "cluster_cpu_high" {
  count       = var.enabled && var.environment == "prod" ? 1 : 0
  
  alerts {
    email = var.alert_emails
    slack {
      channel = var.slack_channel
      url     = var.slack_webhook_url
    }
  }
  
  window      = "5m"
  type        = "v1/insights/droplet/cpu"
  compare     = "GreaterThan"
  value       = 80
  description = "Alerta quando a CPU do cluster ultrapassa 80% por 5 minutos"
  
  entities = [digitalocean_kubernetes_cluster.main[0].id]
  
  # Evitar muitas notificações
  enabled = true
}

resource "digitalocean_monitor_alert" "cluster_memory_high" {
  count       = var.enabled && var.environment == "prod" ? 1 : 0
  
  alerts {
    email = var.alert_emails
    slack {
      channel = var.slack_channel
      url     = var.slack_webhook_url
    }
  }
  
  window      = "5m"
  type        = "v1/insights/droplet/memory_utilization_percent"
  compare     = "GreaterThan"
  value       = 85
  description = "Alerta quando a memória do cluster ultrapassa 85% por 5 minutos"
  
  entities = [digitalocean_kubernetes_cluster.main[0].id]
  
  # Evitar muitas notificações
  enabled = true
}