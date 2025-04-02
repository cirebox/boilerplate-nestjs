// filepath: /home/eric/workspace/cirebox/boilerplate-nestjs/terraform/modules/monitoring/aws/outputs.tf
output "sns_topic_arn" {
  description = "O ARN do tópico SNS usado para alertas"
  value       = aws_sns_topic.alerts.arn
}

output "high_cpu_alarm_arn" {
  description = "O ARN do alarme de CPU alta"
  value       = aws_cloudwatch_metric_alarm.high_cpu.arn
}

output "high_memory_alarm_arn" {
  description = "O ARN do alarme de memória alta"
  value       = aws_cloudwatch_metric_alarm.high_memory.arn
}

output "service_type" {
  description = "O tipo de serviço monitorado (EKS ou ECS)"
  value       = local.service_type
}