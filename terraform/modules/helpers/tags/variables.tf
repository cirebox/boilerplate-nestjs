variable "project_name" {
  description = "Nome do projeto"
  type        = string
}

variable "environment" {
  description = "Ambiente de implantação (dev, staging, prod)"
  type        = string
}

variable "provider_name" {
  description = "Nome do provedor cloud (aws, gcp, azure, digitalocean, local)"
  type        = string

  validation {
    condition     = contains(["aws", "gcp", "azure", "digitalocean", "local"], var.provider_name)
    error_message = "O provedor deve ser um dos seguintes: aws, gcp, azure, digitalocean, local."
  }
}

variable "extra_tags" {
  description = "Tags adicionais a serem aplicadas em todos os recursos"
  type        = map(string)
  default     = {}
}