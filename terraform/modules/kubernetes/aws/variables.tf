variable "environment" {
  description = "Ambiente de deploy (dev, staging, prod)"
  type        = string
}

variable "project_name" {
  description = "Nome do projeto"
  type        = string
}

variable "cluster_version" {
  description = "Versão do Kubernetes a ser usada no cluster EKS"
  type        = string
  default     = "1.26"
}

variable "node_instance_types" {
  description = "Lista de tipos de instância EC2 a serem usados nos node groups"
  type        = list(string)
  default     = ["t3.small"]
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

variable "vpc_id" {
  description = "ID da VPC onde o cluster será implantado"
  type        = string
}

variable "subnet_ids" {
  description = "Lista de IDs de subnets onde os nós do cluster serão implantados"
  type        = list(string)
}

variable "tags" {
  description = "Tags a serem aplicadas a todos os recursos"
  type        = map(string)
  default     = {}
}

variable "multi_az" {
  description = "Se o cluster deve ser distribuído em múltiplas zonas de disponibilidade"
  type        = bool
  default     = false
}