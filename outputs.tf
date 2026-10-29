output "arn_topico" {
  description = "ARN do tópico SNS dos chamados urgentes"
  value       = aws_sns_topic.chamados_urgentes.arn
}

output "url_api" {
  description = "Invoke URL da API"
  value       = aws_apigatewayv2_stage.default.invoke_url
}

output "endpoint_chamados" {
  value = "${aws_apigatewayv2_stage.default.invoke_url}/chamados"
}

output "policy_publicar_manutencao" {
  description = "JSON da policy de menor privilégio — para o PDF de entrega"
  value       = data.aws_iam_policy_document.publicar_manutencao.json
}