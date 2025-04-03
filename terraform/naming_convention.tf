locals {
  # Definição das convenções de nomenclatura para diferentes tipos de recursos
  naming_convention = {
    resource_names = "kebab-case" # ex: my-resource-name
    variable_names = "snake_case" # ex: my_variable_name
    output_names   = "snake_case" # ex: my_output_name
    module_names   = "snake_case" # ex: network_aws
  }

  # Prefixos para diferentes tipos de recursos
  resource_prefixes = {
    # AWS
    aws_vpc            = "vpc"
    aws_subnet         = "subnet"
    aws_security_group = "sg"
    aws_rds            = "rds"
    aws_eks            = "eks"
    aws_iam_role       = "role"
    aws_iam_policy     = "policy"
    aws_lb             = "alb"
    aws_s3             = "s3"

    # GCP
    gcp_network    = "vpc"
    gcp_subnetwork = "subnet"
    gcp_instance   = "vm"
    gcp_gke        = "gke"
    gcp_sql        = "sql"
    gcp_lb         = "lb"
    gcp_bucket     = "bucket"

    # DigitalOcean
    do_vpc     = "vpc"
    do_droplet = "droplet"
    do_k8s     = "k8s"
    do_db      = "db"
    do_lb      = "lb"

    # Azure
    azure_vnet    = "vnet"
    azure_subnet  = "subnet"
    azure_vm      = "vm"
    azure_aks     = "aks"
    azure_db      = "db"
    azure_lb      = "lb"
    azure_storage = "storage"
  }

  # Tags padrão para todos os recursos
  standard_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
    CreatedAt   = timestamp()
  }
}

# Outputs para uso em outros módulos
output "resource_naming" {
  description = "Convenções de nomenclatura para recursos"
  value       = local.naming_convention
}

output "resource_prefixes" {
  description = "Prefixos padrão para tipos de recursos"
  value       = local.resource_prefixes
}

output "standard_tags" {
  description = "Tags padrão para todos os recursos"
  value       = local.standard_tags
}