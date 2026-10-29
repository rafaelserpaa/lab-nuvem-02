output "arn_topico" {
  description = "ARN do tópico SNS dos chamados urgentes"
  value       = aws_sns_topic.chamados_urgentes.arn
}