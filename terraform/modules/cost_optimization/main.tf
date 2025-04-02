# Módulo de Otimização de Custos para infraestruturas na nuvem
# Este módulo implementa:
# 1. Monitoramento de recursos subutilizados
# 2. Desligamento automático de ambientes não produtivos fora do horário comercial
# 3. Alertas de orçamento e uso excessivo

locals {
  # Converter horários de trabalho para segundos desde a meia-noite
  horario_inicio_segundos = tonumber(split(":", var.horario_trabalho_inicio)[0]) * 3600 + tonumber(split(":", var.horario_trabalho_inicio)[1]) * 60
  horario_fim_segundos = tonumber(split(":", var.horario_trabalho_fim)[0]) * 3600 + tonumber(split(":", var.horario_trabalho_fim)[1]) * 60
  
  # Dias da semana em que o desligamento está ativo (1 = segunda, 7 = domingo)
  dias_desligamento = [for dia in var.dias_desligamento : index(["seg", "ter", "qua", "qui", "sex", "sab", "dom"], dia) + 1]
  
  # Tags para identificar recursos gerenciados por este módulo
  resource_tags = merge(
    var.resource_tags,
    {
      managed_by = "terraform-cost-optimization-module"
      auto_shutdown = var.enable_auto_shutdown ? "true" : "false"
    }
  )
}

# Monitoramento de recursos subutilizados usando o DigitalOcean Monitoring
resource "digitalocean_monitor_alert" "cpu_underutilization" {
  count = var.enable_underutilization_monitoring ? 1 : 0
  
  alerts {
    email = var.alert_emails
    slack {
      channel = var.slack_channel
      url = var.slack_webhook_url
    }
  }
  
  window = "5m"
  type = "v1/insights/droplet/cpu"
  compare = "LessThan"
  value = var.cpu_underutilization_threshold
  description = "Alerta de subutilização de CPU - abaixo de ${var.cpu_underutilization_threshold}% por 5 minutos"
  
  entities = var.monitored_droplet_ids
  
  tags = local.resource_tags
}

resource "digitalocean_monitor_alert" "memory_underutilization" {
  count = var.enable_underutilization_monitoring ? 1 : 0
  
  alerts {
    email = var.alert_emails
    slack {
      channel = var.slack_channel
      url = var.slack_webhook_url
    }
  }
  
  window = "5m"
  type = "v1/insights/droplet/memory_utilization_percent"
  compare = "LessThan"
  value = var.memory_underutilization_threshold
  description = "Alerta de subutilização de memória - abaixo de ${var.memory_underutilization_threshold}% por 5 minutos"
  
  entities = var.monitored_droplet_ids
  
  tags = local.resource_tags
}

# Agendamento e automação de desligamento
resource "digitalocean_project_resources" "ambientes_nao_produtivos" {
  count = var.enable_auto_shutdown ? 1 : 0
  project = var.project_id
  resources = var.non_prod_resource_ids
}

# Cloud Function para desligamento automático
resource "digitalocean_spaces_bucket" "automation_code" {
  count = var.enable_auto_shutdown ? 1 : 0
  
  name   = "${var.project_name}-${var.environment}-automation"
  region = var.region
  acl    = "private"
  
  versioning {
    enabled = true
  }
}

# Código para a automação de desligamento
resource "digitalocean_spaces_bucket_object" "shutdown_code" {
  count = var.enable_auto_shutdown ? 1 : 0
  
  bucket = digitalocean_spaces_bucket.automation_code[0].name
  key    = "auto_shutdown.py"
  content = <<-EOT
import requests
import time
import datetime
import os
import sys

# Configuração
API_TOKEN = os.environ.get('DIGITALOCEAN_API_TOKEN')
HEADERS = {'Authorization': f'Bearer {API_TOKEN}', 'Content-Type': 'application/json'}
BASE_URL = 'https://api.digitalocean.com/v2'

# Horário de trabalho
DIAS_DESLIGAMENTO = ${jsonencode(local.dias_desligamento)}
HORARIO_INICIO = ${local.horario_inicio_segundos}  # segundos desde meia-noite
HORARIO_FIM = ${local.horario_fim_segundos}       # segundos desde meia-noite

# Recursos para gerenciar
DROPLET_IDS = ${jsonencode(var.auto_shutdown_droplet_ids)}
DATABASE_IDS = ${jsonencode(var.auto_shutdown_db_ids)}
K8S_IDS = ${jsonencode(var.auto_shutdown_k8s_ids)}

def is_fora_horario_comercial():
    agora = datetime.datetime.now()
    dia_semana = agora.isoweekday()  # 1=segunda, 7=domingo
    
    # Verificar se é um dia de desligamento
    if dia_semana not in DIAS_DESLIGAMENTO:
        return False
    
    # Calcular segundos desde meia-noite
    segundos_agora = agora.hour * 3600 + agora.minute * 60 + agora.second
    
    # Fora do horário comercial se antes do início ou depois do fim
    return segundos_agora < HORARIO_INICIO or segundos_agora > HORARIO_FIM

def desligar_recursos():
    # Desligar droplets
    for droplet_id in DROPLET_IDS:
        requests.post(
            f'{BASE_URL}/droplets/{droplet_id}/actions',
            headers=HEADERS,
            json={'type': 'shutdown'}
        )
        print(f"Desligando droplet {droplet_id}")
    
    # Desligar bancos de dados
    for db_id in DATABASE_IDS:
        requests.put(
            f'{BASE_URL}/databases/{db_id}',
            headers=HEADERS,
            json={'size': 'off'}
        )
        print(f"Desligando banco de dados {db_id}")
    
    # Reduzir Kubernetes para zero
    for k8s_id in K8S_IDS:
        requests.post(
            f'{BASE_URL}/kubernetes/clusters/{k8s_id}/node_pools',
            headers=HEADERS,
            json={'name': 'default-pool', 'count': 0}
        )
        print(f"Reduzindo nós do Kubernetes {k8s_id} para zero")

def ligar_recursos():
    # Ligar droplets
    for droplet_id in DROPLET_IDS:
        requests.post(
            f'{BASE_URL}/droplets/{droplet_id}/actions',
            headers=HEADERS,
            json={'type': 'power_on'}
        )
        print(f"Ligando droplet {droplet_id}")
    
    # Ligar bancos de dados
    for db_id in DATABASE_IDS:
        requests.put(
            f'{BASE_URL}/databases/{db_id}',
            headers=HEADERS,
            json={'size': 'db-s-1vcpu-1gb'}  # Tamanho padrão
        )
        print(f"Ligando banco de dados {db_id}")
    
    # Aumentar Kubernetes para o mínimo
    for k8s_id in K8S_IDS:
        requests.post(
            f'{BASE_URL}/kubernetes/clusters/{k8s_id}/node_pools',
            headers=HEADERS,
            json={'name': 'default-pool', 'count': 1}
        )
        print(f"Aumentando nós do Kubernetes {k8s_id} para 1")

def main():
    if is_fora_horario_comercial():
        print("Fora do horário comercial. Desligando recursos...")
        desligar_recursos()
    else:
        print("Dentro do horário comercial. Ligando recursos...")
        ligar_recursos()

if __name__ == "__main__":
    main()
EOT

  content_type = "text/plain"
}

# Função de automação usando App Platform ou Functions (se disponível)
resource "digitalocean_app" "cost_optimizer" {
  count = var.enable_auto_shutdown ? 1 : 0
  
  spec {
    name   = "${var.project_name}-${var.environment}-cost-optimizer"
    region = var.region
    
    service {
      name               = "cost-optimizer-service"
      instance_count     = 1
      instance_size_slug = "basic-xxs"
      
      github {
        repo           = var.github_repo
        branch         = var.github_branch
        deploy_on_push = true
      }
      
      env {
        key   = "DIGITALOCEAN_API_TOKEN"
        value = var.do_api_token
        type  = "SECRET"
      }
      
      routes {
        path = "/"
      }
      
      run_command = "python3 auto_shutdown.py"
      
      # Executar a cada 30 minutos
      cron_jobs {
        name = "auto-shutdown-job"
        schedule = "*/30 * * * *"
        command = "python3 auto_shutdown.py"
      }
    }
  }
}

# Relatórios de uso e economia - armazenados no Spaces
resource "digitalocean_spaces_bucket" "cost_reports" {
  count = var.enable_cost_reporting ? 1 : 0
  
  name   = "${var.project_name}-${var.environment}-cost-reports"
  region = var.region
  acl    = "private"
}

# Alertas de orçamento para controle de gastos
resource "digitalocean_monitor_alert" "budget_alert" {
  count = var.enable_budget_alerts ? 1 : 0
  
  alerts {
    email = var.alert_emails
    slack {
      channel = var.slack_channel
      url = var.slack_webhook_url
    }
  }
  
  window = "24h"
  type = "v1/insights/droplet/spend"
  compare = "GreaterThan"
  value = var.budget_threshold
  description = "Alerta de orçamento - gasto acima de $${var.budget_threshold} em 24 horas"
  
  entities = var.monitored_droplet_ids
}

# Script local para gerar relatório de economia
resource "null_resource" "savings_estimator" {
  count = var.enable_cost_reporting ? 1 : 0
  
  triggers = {
    report_time = timestamp()
  }
  
  provisioner "local-exec" {
    command = <<-EOT
      echo "Estimativa de economia com otimizações:"
      echo "- Desligamento automático: Aproximadamente $$(( ${length(var.auto_shutdown_droplet_ids)} * 5 * (24 - ${local.horario_fim_segundos / 3600 - local.horario_inicio_segundos / 3600}) * ${length(var.dias_desligamento)} * 4 / 100)) por mês"
      echo "- Monitoramento de subutilização: Potencial economia adicional de 10-30% com redimensionamento"
      echo "Relatório gerado em $$(date) para ambiente ${var.environment}" 
      echo "Economia total estimada: $$(( ${length(var.auto_shutdown_droplet_ids)} * 5 * (24 - ${local.horario_fim_segundos / 3600 - local.horario_inicio_segundos / 3600}) * ${length(var.dias_desligamento)} * 4 / 100 + ${length(var.auto_shutdown_droplet_ids)} * 5 * 0.2 )) por mês"
    EOT
  }
}

