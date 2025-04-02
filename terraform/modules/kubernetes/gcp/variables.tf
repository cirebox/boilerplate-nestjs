variable "environment" {
  description = "Ambiente de deploy (dev, staging, prod)"
  type        = string
}

variable "project_name" {
  description = "Nome do projeto"
  type        = string
}

variable "project_id" {
  description = "ID do projeto GCP"
  type        = string
}

variable "region" {
  description = "Região GCP"
  type        = string
  default     = "us-central1"
}

variable "cluster_version" {
  description = "Versão do Kubernetes a ser usada no cluster GKE"
  type        = string
  default     = "1.26"
}

variable "vpc_self_link" {
  description = "Self-link da VPC onde o cluster será implantado"
  type        = string
}

variable "subnet_self_link" {
  description = "Self-link da subnet onde o cluster será implantado"
  type        = string
}

variable "node_instance_types" {
  description = "Lista de tipos de instância GCE a serem usados nos node pools"
  type        = list(string)
  default     = ["e2-standard-2"]
}

variable "min_nodes" {
  description = "Número mínimo de nós no cluster"
  type        = number
  default     = 1
}

variable "max_nodes" {
  description = "Número máximo de nós no cluster"
  type        = number
  default     = 5
}

variable "desired_nodes" {
  description = "Número desejado de nós no cluster"
  type        = number
  default     = 2
}

variable "master_authorized_networks" {
  description = "Lista de CIDRs autorizados a acessar o plano de controle Kubernetes"
  type = list(object({
    cidr_block   = string
    display_name = string
  }))
  default = [{
    cidr_block   = "0.0.0.0/0"
    display_name = "All"
  }]
}

variable "notification_channel_ids" {
  description = "IDs dos canais de notificação do Cloud Monitoring para alertas"
  type        = list(string)
  default     = []
}

variable "multi_az" {
  description = "Se o cluster deve ser distribuído em múltiplas zonas (regional)"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags a serem aplicadas a todos os recursos"
  type        = map(string)
  default     = {}
}