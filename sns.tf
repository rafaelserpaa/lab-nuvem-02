resource "aws_sns_topic" "chamados_urgentes" {
  name = "chamados-urgentes"
}

resource "aws_sns_topic_subscription" "plantao_email" {
  topic_arn = aws_sns_topic.chamados_urgentes.arn
  protocol  = "email"
  endpoint  = var.email_plantao
}