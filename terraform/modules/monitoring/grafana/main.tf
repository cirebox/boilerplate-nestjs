# Módulo Terraform para implantação e configuração do Grafana
# Este módulo configura o Grafana para monitoramento da infraestrutura

variable "project_name" {
  description = "Nome do projeto"
  type        = string
}

variable "environment" {
  description = "Ambiente de implantação (dev, staging, prod)"
  type        = string
}

variable "kubernetes_namespace" {
  description = "Namespace do Kubernetes onde o Grafana será implantado"
  type        = string
  default     = "monitoring"
}

variable "grafana_admin_password" {
  description = "Senha de administrador do Grafana"
  type        = string
  sensitive   = true
}

variable "grafana_version" {
  description = "Versão do Grafana a ser implantada"
  type        = string
  default     = "9.3.6"
}

variable "retention_days" {
  description = "Número de dias para retenção de dados"
  type        = number
  default     = 30
}

variable "prometheus_url" {
  description = "URL do Prometheus que o Grafana usará como fonte de dados"
  type        = string
}

variable "alert_notification_channels" {
  description = "Canais de notificação de alertas (email, slack, etc)"
  type = list(object({
    name     = string
    type     = string
    settings = map(string)
  }))
  default = []
}

# Cria namespace se não existir
resource "kubernetes_namespace" "monitoring" {
  count = var.kubernetes_namespace == "monitoring" ? 1 : 0

  metadata {
    name = var.kubernetes_namespace
    labels = {
      "app.kubernetes.io/managed-by" = "terraform"
      "app.kubernetes.io/part-of"    = var.project_name
      "environment"                  = var.environment
    }
  }

  lifecycle {
    prevent_destroy = true
  }
}

# Configura o Grafana via Helm chart
resource "helm_release" "grafana" {
  name       = "grafana"
  repository = "https://grafana.github.io/helm-charts"
  chart      = "grafana"
  version    = var.grafana_version
  namespace  = var.kubernetes_namespace

  # Aguarda a criação do namespace se for necessário
  depends_on = [kubernetes_namespace.monitoring]

  # Configurações do Grafana
  set {
    name  = "adminPassword"
    value = var.grafana_admin_password
  }

  set {
    name  = "persistence.enabled"
    value = "true"
  }

  set {
    name  = "persistence.size"
    value = "10Gi"
  }

  # Configurações de serviço
  set {
    name  = "service.type"
    value = "ClusterIP"
  }

  # Configuração de recursos
  set {
    name  = "resources.limits.cpu"
    value = "500m"
  }

  set {
    name  = "resources.limits.memory"
    value = "512Mi"
  }

  set {
    name  = "resources.requests.cpu"
    value = "200m"
  }

  set {
    name  = "resources.requests.memory"
    value = "256Mi"
  }

  # Configuração de ingress para acesso externo
  set {
    name  = "ingress.enabled"
    value = "true"
  }

  set {
    name  = "ingress.annotations.kubernetes\\.io/ingress\\.class"
    value = "nginx"
  }

  set {
    name  = "ingress.hosts[0]"
    value = "grafana-${var.environment}.${var.project_name}.com"
  }

  set {
    name  = "ingress.tls[0].secretName"
    value = "grafana-tls"
  }

  set {
    name  = "ingress.tls[0].hosts[0]"
    value = "grafana-${var.environment}.${var.project_name}.com"
  }

  # Arquivo de valores para configurações mais complexas
  values = [
    templatefile("${path.module}/templates/grafana-values.yaml", {
      prometheus_url = var.prometheus_url
      retention_days = var.retention_days
      project_name   = var.project_name
      environment    = var.environment
    })
  ]
}

# Configuração de fonte de dados do Prometheus
resource "kubernetes_config_map" "grafana_datasources" {
  metadata {
    name      = "grafana-datasources"
    namespace = var.kubernetes_namespace
  }

  data = {
    "datasources.yaml" = <<-EOF
      apiVersion: 1
      datasources:
      - name: Prometheus
        type: prometheus
        url: ${var.prometheus_url}
        access: proxy
        isDefault: true
        editable: false
        version: 1
    EOF
  }

  depends_on = [helm_release.grafana]
}

# Dashboards para infraestrutura
resource "kubernetes_config_map" "grafana_dashboards_provider" {
  metadata {
    name      = "grafana-dashboards-provider"
    namespace = var.kubernetes_namespace
  }

  data = {
    "dashboards.yaml" = <<-EOF
      apiVersion: 1
      providers:
      - name: 'default'
        orgId: 1
        folder: 'Infrastructure'
        type: file
        disableDeletion: false
        editable: false
        updateIntervalSeconds: 30
        options:
          path: /var/lib/grafana/dashboards
    EOF
  }

  depends_on = [helm_release.grafana]
}

# Dashboard principal para estado da infraestrutura
resource "kubernetes_config_map" "infrastructure_dashboard" {
  metadata {
    name      = "infrastructure-dashboard"
    namespace = var.kubernetes_namespace
  }

  data = {
    "infrastructure-overview.json" = templatefile("${path.module}/templates/infrastructure-dashboard.json", {
      project_name = var.project_name
      environment  = var.environment
    })
  }

  depends_on = [kubernetes_config_map.grafana_dashboards_provider]
}

# Dashboard para monitoramento de clusters Kubernetes
resource "kubernetes_config_map" "kubernetes_dashboard" {
  metadata {
    name      = "kubernetes-dashboard"
    namespace = var.kubernetes_namespace
  }

  data = {
    "kubernetes-cluster.json" = templatefile("${path.module}/templates/kubernetes-dashboard.json", {
      project_name = var.project_name
      environment  = var.environment
    })
  }

  depends_on = [kubernetes_config_map.grafana_dashboards_provider]
}

# Dashboard para monitoramento de banco de dados
resource "kubernetes_config_map" "database_dashboard" {
  metadata {
    name      = "database-dashboard"
    namespace = var.kubernetes_namespace
  }

  data = {
    "database-monitoring.json" = templatefile("${path.module}/templates/database-dashboard.json", {
      project_name = var.project_name
      environment  = var.environment
    })
  }

  depends_on = [kubernetes_config_map.grafana_dashboards_provider]
}

# Dashboard para monitoramento de custos
resource "kubernetes_config_map" "cost_dashboard" {
  metadata {
    name      = "cost-dashboard"
    namespace = var.kubernetes_namespace
  }

  data = {
    "cost-analysis.json" = templatefile("${path.module}/templates/cost-dashboard.json", {
      project_name = var.project_name
      environment  = var.environment
    })
  }

  depends_on = [kubernetes_config_map.grafana_dashboards_provider]
}

# Configuração de alertas do Grafana
resource "kubernetes_config_map" "grafana_alerts" {
  metadata {
    name      = "grafana-alerts"
    namespace = var.kubernetes_namespace
  }

  data = {
    "alerts.yaml" = templatefile("${path.module}/templates/alerts.yaml", {
      project_name = var.project_name
      environment  = var.environment
    })
  }

  depends_on = [helm_release.grafana]
}

# Configuração de canais de notificação para alertas
resource "null_resource" "notification_channels" {
  count = length(var.alert_notification_channels)

  triggers = {
    grafana_url = helm_release.grafana.status
    channel     = jsonencode(var.alert_notification_channels[count.index])
  }

  # Cria canais de notificação via API do Grafana
  provisioner "local-exec" {
    command = <<-EOT
      #!/bin/bash
      set -e
      
      # Esperar até que o Grafana esteja pronto
      echo "Aguardando o Grafana estar pronto..."
      sleep 30
      
      # Configurar canal de notificação
      CHANNEL_NAME="${var.alert_notification_channels[count.index].name}"
      CHANNEL_TYPE="${var.alert_notification_channels[count.index].type}"
      SETTINGS='${jsonencode(var.alert_notification_channels[count.index].settings)}'
      
      # Obter porta do Grafana
      GRAFANA_PORT=$(kubectl get svc grafana -n ${var.kubernetes_namespace} -o jsonpath='{.spec.ports[0].port}')
      
      # Configurar port forwarding temporário
      kubectl port-forward svc/grafana -n ${var.kubernetes_namespace} 3000:$GRAFANA_PORT &
      PID=$!
      sleep 5
      
      # Criar canal de notificação
      curl -X POST -H "Content-Type: application/json" \
        -H "Authorization: Basic $(echo -n admin:${var.grafana_admin_password} | base64)" \
        --data "{\"name\":\"$CHANNEL_NAME\",\"type\":\"$CHANNEL_TYPE\",\"settings\":$SETTINGS}" \
        http://localhost:3000/api/alert-notifications
      
      # Encerrar port forwarding
      kill $PID
    EOT
  }

  depends_on = [helm_release.grafana]
}

# Outputs do módulo
output "grafana_url" {
  description = "URL do Grafana"
  value       = "https://grafana-${var.environment}.${var.project_name}.com"
}

output "grafana_admin_user" {
  description = "Usuário administrador do Grafana"
  value       = "admin"
}

output "grafana_namespace" {
  description = "Namespace onde o Grafana está implantado"
  value       = var.kubernetes_namespace
}

