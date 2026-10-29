output "function_name" {
  value = aws_lambda_function.registrar_chamado.function_name
}

output "invoke_arn" {
  value = aws_lambda_function.registrar_chamado.invoke_arn
}

output "policy_publicar_manutencao" {
  value = data.aws_iam_policy_document.publicar_manutencao.json
}
