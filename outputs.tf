output "arn_topico" {
  description = "ARN do tópico SNS dos chamados urgentes"
  value       = module.notificacoes.topico_arn
}

output "url_api" {
  description = "Invoke URL da API"
  value       = module.api.invoke_url
}

output "endpoint_chamados" {
  value = "${module.api.invoke_url}/chamados"
}

output "policy_publicar_manutencao" {
  description = "JSON da policy de menor privilégio — para o PDF de entrega"
  value       = module.registrar_chamado.policy_publicar_manutencao
}
