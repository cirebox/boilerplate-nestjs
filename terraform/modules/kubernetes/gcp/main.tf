/**
 * Módulo de Kubernetes (GKE) para GCP
 * 
 * Este módulo cria um cluster Google Kubernetes Engine (GKE) otimizado
 * para controle de custos e flexibilidade.
 */

locals {
  cluster_name = "${var.project_name}-${var.environment}-gke"
  node_pools   = var.environment == "prod" ? ["default", "system"] : ["default"]
}

# Cluster GKE
resource "google_container_cluster" "primary" {
  name     = local.cluster_name
  location = var.region
  project  = var.project_id

  # Configuração para controle de custos: remover node pool padrão
  # e usar um node pool gerenciado separadamente
  remove_default_node_pool = true
  initial_node_count       = 1

  # Especificar a versão do Kubernetes
  min_master_version = var.cluster_version

  # Configuração de rede
  network    = var.vpc_self_link
  subnetwork = var.subnet_self_link

  # Configuração para economia de custos em redes: reutilizar IPs
  ip_allocation_policy {
    cluster_ipv4_cidr_block  = "/14"
    services_ipv4_cidr_block = "/20"
  }

  # Configuração de acesso à API do Kubernetes
  private_cluster_config {
    enable_private_nodes    = var.environment == "prod"
    enable_private_endpoint = false
    master_ipv4_cidr_block  = "172.16.0.0/28"
  }

  # Configuração de registro (logging) e monitoramento
  logging_service    = var.environment == "prod" ? "logging.googleapis.com/kubernetes" : "none"
  monitoring_service = var.environment == "prod" ? "monitoring.googleapis.com/kubernetes" : "none"

  # Configuração de segurança
  master_auth {
    # Desabilitar autenticação básica por razões de segurança
    client_certificate_config {
      issue_client_certificate = false
    }
  }

  # Configuração de segurança de rede
  master_authorized_networks_config {
    dynamic "cidr_blocks" {
      for_each = var.master_authorized_networks
      content {
        cidr_block   = cidr_blocks.value.cidr_block
        display_name = cidr_blocks.value.display_name
      }
    }
  }

  # Habilitar o modo de controle de acesso baseado em RBAC
  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }

  # Configurações para controle de custos
  addons_config {
    http_load_balancing {
      disabled = false
    }
    horizontal_pod_autoscaling {
      disabled = false
    }
    # Controle de custos: Desativar Cloud Run por padrão
    cloudrun_config {
      disabled = true
    }

    # Nota: istio_config foi removido pois não é mais suportado no provedor GCP
  }

  # Configuração de manutenção - horário de baixo tráfego
  maintenance_policy {
    daily_maintenance_window {
      start_time = "02:00"
    }
  }

  # Configuração de Vertical Pod Autoscaler para melhor utilização de recursos
  vertical_pod_autoscaling {
    enabled = true
  }

  # Rótulos para rastreamento de custos
  resource_labels = merge(var.tags, {
    environment = var.environment
    project     = var.project_name
    managed-by  = "terraform"
  })

  # Proteção para evitar destruição acidental
  lifecycle {
    prevent_destroy = false # Em produção, considere alterar para true
    ignore_changes  = [node_config, initial_node_count]
  }
}

# Node pool principal
resource "google_container_node_pool" "default" {
  name               = "${local.cluster_name}-default-pool"
  location           = var.region
  cluster            = google_container_cluster.primary.name
  project            = var.project_id
  initial_node_count = var.desired_nodes

  # Configuração de auto-scaling para economizar custos
  autoscaling {
    min_node_count = var.min_nodes
    max_node_count = var.max_nodes
  }

  # Configurações de gerenciamento dos nós
  management {
    auto_repair  = true
    auto_upgrade = true
  }

  # Configurações de atualização gradual
  upgrade_settings {
    max_surge       = 1
    max_unavailable = 0
  }

  # Configuração do nó
  node_config {
    machine_type = var.node_instance_types[0]
    disk_size_gb = 50
    disk_type    = "pd-standard" # Controle de custos: use pd-standard em vez de pd-ssd

    # Para economizar custos: utilizar preemptive VMs em ambientes não produtivos
    preemptible = var.environment != "prod"

    # Controle de custos: spot VMs são mais baratos
    spot = var.environment != "prod"

    # Metadados para auto-reparação e auto-upgrade
    metadata = {
      disable-legacy-endpoints = "true"
    }

    # Rótulos para os nós
    labels = {
      environment = var.environment
      role        = "default"
    }

    # Tags de rede para os nós
    tags = ["gke-${local.cluster_name}", "default-pool"]

    # Escopos OAuth para as instâncias
    oauth_scopes = [
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
      "https://www.googleapis.com/auth/devstorage.read_only"
    ]

    # Configuração de Workload Identity
    workload_metadata_config {
      mode = "GKE_METADATA"
    }
  }

  # Depende do cluster
  depends_on = [google_container_cluster.primary]
}

# Node pool adicional para serviços de sistema (somente em produção)
resource "google_container_node_pool" "system" {
  count              = var.environment == "prod" ? 1 : 0
  name               = "${local.cluster_name}-system-pool"
  location           = var.region
  cluster            = google_container_cluster.primary.name
  project            = var.project_id
  initial_node_count = 1

  # Configuração de auto-scaling para economizar custos
  autoscaling {
    min_node_count = 1
    max_node_count = 2
  }

  # Configurações de gerenciamento dos nós
  management {
    auto_repair  = true
    auto_upgrade = true
  }

  # Configuração do nó
  node_config {
    machine_type = "e2-small" # Instâncias menores para serviços de sistema
    disk_size_gb = 30
    disk_type    = "pd-standard"

    # Não usar preemptible para nós de sistema para garantir estabilidade
    preemptible = false

    # Rótulos para os nós
    labels = {
      environment = var.environment
      role        = "system"
    }

    # Taint para que apenas serviços de sistema sejam agendados neste pool
    taint {
      key    = "dedicated"
      value  = "system"
      effect = "PREFER_NO_SCHEDULE"
    }

    # Tags de rede para os nós
    tags = ["gke-${local.cluster_name}", "system-pool"]

    # Escopos OAuth para as instâncias
    oauth_scopes = [
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
      "https://www.googleapis.com/auth/devstorage.read_only"
    ]

    # Configuração de Workload Identity
    workload_metadata_config {
      mode = "GKE_METADATA"
    }
  }

  # Depende do cluster
  depends_on = [
    google_container_cluster.primary,
    google_container_node_pool.default
  ]
}

# Service Account para o Cluster Autoscaler
resource "google_service_account" "cluster_autoscaler" {
  account_id   = "${local.cluster_name}-autoscaler"
  display_name = "Service Account para o Cluster Autoscaler do GKE ${local.cluster_name}"
  project      = var.project_id
}

# IAM binding para permitir que o Cluster Autoscaler escale o cluster
resource "google_project_iam_member" "cluster_autoscaler" {
  project = var.project_id
  role    = "roles/container.developer"
  member  = "serviceAccount:${google_service_account.cluster_autoscaler.email}"
}

# Métricas para monitoramento de custos e utilização
resource "google_monitoring_alert_policy" "node_cpu_high" {
  count        = var.environment == "prod" ? 1 : 0
  display_name = "${local.cluster_name} - Alta Utilização de CPU nos Nós"
  project      = var.project_id
  combiner     = "OR"

  conditions {
    display_name = "Alta utilização de CPU nos nós do GKE"

    condition_threshold {
      filter          = "resource.type = \"k8s_node\" AND resource.labels.project_id = \"${var.project_id}\" AND resource.labels.location = \"${var.region}\" AND resource.labels.cluster_name = \"${local.cluster_name}\" AND metric.type = \"kubernetes.io/node/cpu/allocatable_utilization\""
      duration        = "300s"
      comparison      = "COMPARISON_GT"
      threshold_value = 0.8

      aggregations {
        alignment_period     = "300s"
        per_series_aligner   = "ALIGN_MEAN"
        cross_series_reducer = "REDUCE_MEAN"
      }

      trigger {
        count = 1
      }
    }
  }

  notification_channels = var.notification_channel_ids

  documentation {
    content   = "Os nós do cluster ${local.cluster_name} estão com alta utilização de CPU. Considere escalar o cluster ou otimizar a utilização dos recursos."
    mime_type = "text/markdown"
  }
}

# Alerta para alta utilização de memória
resource "google_monitoring_alert_policy" "node_memory_high" {
  count        = var.environment == "prod" ? 1 : 0
  display_name = "${local.cluster_name} - Alta Utilização de Memória nos Nós"
  project      = var.project_id
  combiner     = "OR"

  conditions {
    display_name = "Alta utilização de memória nos nós do GKE"

    condition_threshold {
      filter          = "resource.type = \"k8s_node\" AND resource.labels.project_id = \"${var.project_id}\" AND resource.labels.location = \"${var.region}\" AND resource.labels.cluster_name = \"${local.cluster_name}\" AND metric.type = \"kubernetes.io/node/memory/allocatable_utilization\""
      duration        = "300s"
      comparison      = "COMPARISON_GT"
      threshold_value = 0.8

      aggregations {
        alignment_period     = "300s"
        per_series_aligner   = "ALIGN_MEAN"
        cross_series_reducer = "REDUCE_MEAN"
      }

      trigger {
        count = 1
      }
    }
  }

  notification_channels = var.notification_channel_ids

  documentation {
    content   = "Os nós do cluster ${local.cluster_name} estão com alta utilização de memória. Considere escalar o cluster ou otimizar a utilização dos recursos."
    mime_type = "text/markdown"
  }
}