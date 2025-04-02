# Outputs do módulo de snapshots

output "database_snapshot_trigger" {
  description = "Trigger utilizado para iniciar o snapshot de banco de dados"
  value       = var.enable_db_snapshots ? null_resource.database_snapshot[0].triggers : null
}

output "volume_snapshots" {
  description = "IDs dos snapshots de volume criados"
  value       = var.enable_volume_snapshots ? {
    for key, snapshot in digitalocean_volume_snapshot.volume_snapshots : 
    key => {
      id = snapshot.id
      name = snapshot.name
      created_at = snapshot.created_at
    }
  } : {}
}

output "k8s_backup_installed" {
  description = "Indica se o Velero para backup do Kubernetes foi instalado"
  value       = var.enable_k8s_config_backups ? true : false
}

output "k8s_backup_schedule" {
  

