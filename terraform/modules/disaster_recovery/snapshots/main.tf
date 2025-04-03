# Módulo de recuperação de desastres - Snapshots

# O bloco terraform com required_providers foi removido, pois agora as versões dos providers
# são gerenciadas centralmente no arquivo versions.tf na raiz do diretório terraform

locals {
  snapshot_prefix = "${var.environment}-${var.project_name}"
  current_time    = timestamp()

  # Calcula a data de expiração para snapshots antigos baseado na política de retenção
  expiration_date = timeadd(local.current_time, "${- 1 * var.retention_days * 24}h")

  # Labels comuns para todos os snapshots
  common_tags = {
    "managed-by"  = "terraform"
    "environment" = var.environment
    "project"     = var.project_name
    "module"      = "disaster-recovery"
    "created-at"  = local.current_time
  }
}

# 1. Snapshots de banco de dados (PostgreSQL)
resource "digitalocean_database_cluster_firewall" "backup_access" {
  count      = var.enable_db_snapshots ? 1 : 0
  cluster_id = var.database_cluster_id

  rule {
    type  = "ip_addr"
    value = var.backup_server_ip
  }
}

resource "null_resource" "database_snapshot" {
  count = var.enable_db_snapshots ? 1 : 0

  triggers = {
    # Gera um snapshot baseado no cronograma configurado
    schedule_trigger = formatdate("YYYY-MM-DD-hh-mm", timestamp())
  }

  provisioner "local-exec" {
    command = <<-EOT
      curl -X POST \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer ${var.do_token}" \
        -d '{"name": "${local.snapshot_prefix}-db-snapshot-${formatdate("YYYYMMDDhhmm", timestamp())}", "tags": ["${join("\",\"", [for k, v in local.common_tags : "${k}:${v}"])}"] }' \
        "https://api.digitalocean.com/v2/databases/${var.database_cluster_id}/backups"
    EOT
  }

  # Executa conforme o cronograma configurado
  lifecycle {
    create_before_destroy = true
  }
}

# 2. Snapshots de Volumes Persistentes
resource "digitalocean_volume_snapshot" "volume_snapshots" {
  for_each = var.enable_volume_snapshots ? var.volumes_to_snapshot : {}

  volume_id = each.value.id
  name      = "${local.snapshot_prefix}-vol-snapshot-${each.key}-${formatdate("YYYYMMDDhhmm", timestamp())}"
  tags      = [for k, v in merge(local.common_tags, each.value.tags) : "${k}:${v}"]
}

# 3. Backup das configurações do Kubernetes usando Velero
resource "helm_release" "velero" {
  count            = var.enable_k8s_config_backups ? 1 : 0
  name             = "velero"
  repository       = "https://vmware-tanzu.github.io/helm-charts"
  chart            = "velero"
  namespace        = "velero"
  create_namespace = true

  set {
    name  = "configuration.provider"
    value = "digitalocean"
  }

  set {
    name  = "configuration.backupStorageLocation.bucket"
    value = var.backup_bucket_name
  }

  set {
    name  = "configuration.backupStorageLocation.config.region"
    value = var.region
  }

  set {
    name  = "credentials.secretContents.cloud"
    value = <<-EOF
      [default]
      aws_access_key_id=${var.spaces_access_key}
      aws_secret_access_key=${var.spaces_secret_key}
    EOF
  }

  set {
    name  = "schedules.daily-backup.schedule"
    value = var.k8s_backup_cron_schedule
  }

  set {
    name  = "schedules.daily-backup.template.ttl"
    value = "${var.retention_days * 24}h0m0s"
  }
}

# 4. Eliminação de snapshots antigos para manter a política de retenção
resource "null_resource" "cleanup_old_snapshots" {
  depends_on = [
    digitalocean_volume_snapshot.volume_snapshots,
    null_resource.database_snapshot
  ]

  triggers = {
    # Executa a limpeza uma vez por dia
    daily_trigger = formatdate("YYYY-MM-DD", timestamp())
  }

  provisioner "local-exec" {
    command = <<-EOT
      # Lista e remove snapshots de volumes expirados
      expired_volume_snapshots=$(curl -s -X GET \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer ${var.do_token}" \
        "https://api.digitalocean.com/v2/snapshots?resource_type=volume&tag_name=environment:${var.environment}" | \
        jq -r '.snapshots[] | select(.tags[] | contains("created-at:") and (. | split(":")[1] | strptime("%Y-%m-%dT%H:%M:%S") | mktime) < ${formatdate("YYYYMMDDhhmmss", local.expiration_date)}) | .id')
      
      for snapshot_id in $expired_volume_snapshots; do
        curl -s -X DELETE \
          -H "Content-Type: application/json" \
          -H "Authorization: Bearer ${var.do_token}" \
          "https://api.digitalocean.com/v2/snapshots/$snapshot_id"
        echo "Deleted expired volume snapshot: $snapshot_id"
      done
      
      # Lista e remove snapshots de banco de dados expirados (somente os manuais, não os automatizados pelo DO)
      expired_db_snapshots=$(curl -s -X GET \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer ${var.do_token}" \
        "https://api.digitalocean.com/v2/databases/${var.database_cluster_id}/backups" | \
        jq -r '.backups[] | select(.created_at | strptime("%Y-%m-%dT%H:%M:%S") | mktime) < ${formatdate("YYYYMMDDhhmmss", local.expiration_date)} | .id')
      
      for snapshot_id in $expired_db_snapshots; do
        curl -s -X DELETE \
          -H "Content-Type: application/json" \
          -H "Authorization: Bearer ${var.do_token}" \
          "https://api.digitalocean.com/v2/databases/${var.database_cluster_id}/backups/$snapshot_id"
        echo "Deleted expired database backup: $snapshot_id"
      done
    EOT
  }
}

# 5. Monitoramento do status dos backups e alertas para falhas
resource "null_resource" "backup_status_check" {
  depends_on = [
    null_resource.database_snapshot,
    digitalocean_volume_snapshot.volume_snapshots,
    helm_release.velero
  ]

  triggers = {
    # Verifica o status dos backups diariamente
    daily_check = formatdate("YYYY-MM-DD", timestamp())
  }

  provisioner "local-exec" {
    command = <<-EOT
      # Verificar status dos backups de banco de dados
      db_backup_status=$(curl -s -X GET \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer ${var.do_token}" \
        "https://api.digitalocean.com/v2/databases/${var.database_cluster_id}/backups" | \
        jq -r '.backups[0].status')
      
      if [ "$db_backup_status" != "available" ]; then
        echo "ALERTA: O último backup de banco de dados está com status: $db_backup_status"
        # Enviar notificação via webhook se configurado
        ${var.alert_webhook_url != "" ? "curl -X POST -H 'Content-Type: application/json' -d '{\"text\":\"ALERTA: Backup do banco de dados falhou com status: $db_backup_status\"}' ${var.alert_webhook_url}" : "echo \"Webhook não configurado\""}
      else
        echo "Backup de banco de dados está disponível e íntegro"
      fi
      
      # Verificar backups do Kubernetes (se Velero estiver habilitado)
      if [ ${var.enable_k8s_config_backups} -eq 1 ]; then
        kubectl get backup --namespace velero --no-headers | awk '{print $1, $3}' | while read -r backup_name status; do
          if [ "$status" != "Completed" ]; then
            echo "ALERTA: Backup do Kubernetes $backup_name falhou com status: $status"
            # Enviar notificação via webhook se configurado
            ${var.alert_webhook_url != "" ? "curl -X POST -H 'Content-Type: application/json' -d '{\"text\":\"ALERTA: Backup do Kubernetes $backup_name falhou com status: $status\"}' ${var.alert_webhook_url}" : "echo \"Webhook não configurado\""}
          else
            echo "Backup do Kubernetes $backup_name está completo e íntegro"
          fi
        done
      fi
    EOT
  }
}

