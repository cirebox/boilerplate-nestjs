output "budget_arn" {
  description = "ARN do orçamento criado"
  value       = aws_budgets_budget.monthly.arn
}

output "sns_topic_arn" {
  description = "ARN do tópico SNS para alertas de orçamento"
  value       = aws_sns_topic.billing_alerts.arn
}

output "cost_report_bucket" {
  description = "Nome do bucket S3 para relatórios de custo"
  value       = aws_s3_bucket.cost_reports.bucket
}

output "estimated_monthly_cost" {
  description = "Estimativa de custos mensais com base nas configurações atuais"
  value       = var.budget_amount
}

output "optimization_tips" {
  description = "Dicas para otimização de custos na AWS"
  value = [
    "1. Use instâncias reservadas para workloads previsíveis para economizar até 72%",
    "2. Implemente auto scaling para escalar automaticamente de acordo com a demanda",
    "3. Use classes de armazenamento S3 com ciclo de vida para dados acessados com menos frequência",
    "4. Desligue ambientes não produtivos durante períodos de inatividade (noites/fins de semana)",
    "5. Configure o RDS para parar em ambientes não produtivos quando não estiverem em uso",
    "6. Use o AWS Cost Explorer para identificar tendências e oportunidades de economia",
    "7. Ative o Savings Plans para compromissos de uso de 1 ou 3 anos com descontos significativos",
    "8. Remova recursos não utilizados como volumes EBS órfãos, IPs elásticos não associados",
    "9. Utilize NAT Gateways compartilhados em vez de múltiplos gateways por ambiente",
    "10. Monitore o ambiente regularmente usando o AWS Trusted Advisor"
  ]
}