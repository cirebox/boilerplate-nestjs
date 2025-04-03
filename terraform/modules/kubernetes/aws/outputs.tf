output "cluster_id" {
  description = "ID do cluster EKS"
  value       = aws_eks_cluster.main.id
}

output "cluster_endpoint" {
  description = "Endpoint para acessar o API server do Kubernetes"
  value       = aws_eks_cluster.main.endpoint
}

output "cluster_certificate_authority_data" {
  description = "Certificado de autoridade do cluster Kubernetes"
  value       = aws_eks_cluster.main.certificate_authority[0].data
}

output "cluster_name" {
  description = "Nome do cluster EKS"
  value       = aws_eks_cluster.main.name
}

output "cluster_security_group_id" {
  description = "ID do grupo de segurança associado ao cluster"
  value       = aws_security_group.eks_cluster.id
}

output "node_group_id" {
  description = "ID do grupo de nós EKS"
  value       = aws_eks_node_group.primary.id
}

output "kubectl_config_command" {
  description = "Comando para configurar o kubectl com o novo cluster"
  value       = "aws eks update-kubeconfig --name ${aws_eks_cluster.main.name} --region ${data.aws_region.current.name}"
}

output "autoscaler_role_arn" {
  description = "ARN da role IAM para o Cluster Autoscaler"
  value       = aws_iam_role.cluster_autoscaler.arn
}

output "estimated_monthly_cost" {
  description = "Estimativa de custos mensais com base nas configurações atuais"
  value = {
    control_plane = {
      cost    = "73-146 USD/mês (depende da região)"
      details = "O plano de controle do EKS tem um custo fixo, independentemente do tamanho do cluster"
    }
    worker_nodes = {
      count = var.desired_nodes
      types = var.node_instance_types
      cost_estimate = var.node_instance_types[0] == "t3.small" ? "20-30 USD/mês por nó" : (
        var.node_instance_types[0] == "t3.medium" ? "40-50 USD/mês por nó" :
      "Verificar calculadora AWS")
      total_estimate = "${var.desired_nodes * (
        var.node_instance_types[0] == "t3.small" ? 25 : (
          var.node_instance_types[0] == "t3.medium" ? 45 :
        75))}-${var.desired_nodes * (
        var.node_instance_types[0] == "t3.small" ? 30 : (
          var.node_instance_types[0] == "t3.medium" ? 50 :
      100))} USD/mês (total estimado)"
      savings = var.environment != "prod" ? "Economia com uso de instâncias spot: até 70%" : "Instâncias On-Demand para maior confiabilidade"
    }
    networking = {
      cost = "Depende do tráfego, aproximadamente 10-50 USD/mês"
    }
  }
}

output "cost_optimization_tips" {
  description = "Dicas para otimização de custos do EKS"
  value = [
    "1. Ajuste o número de nós conforme a utilização real da aplicação",
    "2. Use instâncias spot para cargas de trabalho não críticas",
    "3. Utilize o Kubernetes Cluster Autoscaler para escalar automaticamente os nós",
    "4. Considere o uso do Horizontal Pod Autoscaler para ajustar o número de pods",
    "5. Analise e dimensione corretamente os recursos de CPU e memória dos pods",
    "6. Ative o escalonamento para zero nos ambientes não produtivos durante períodos de inatividade",
    "7. Use namespaces para melhor organização e controle de recursos",
    "8. Monitore os custos regularmente com o AWS Cost Explorer",
    "9. Implemente Resource Quotas e Limit Ranges para evitar sobre-alocação"
  ]
}