data "archive_file" "auditar_chamado" {
  type        = "zip"
  source_file = var.source_file
  output_path = var.output_path
}

resource "aws_cloudwatch_log_group" "auditar_chamado" {
  name              = "/aws/lambda/auditar-chamado"
  retention_in_days = 7
}

resource "aws_lambda_function" "auditar_chamado" {
  function_name = "auditar-chamado"
  role          = aws_iam_role.auditar_chamado.arn
  handler       = "auditar_chamado.lambda_handler"
  runtime       = "python3.13"

  filename         = data.archive_file.auditar_chamado.output_path
  source_code_hash = data.archive_file.auditar_chamado.output_base64sha256

  timeout     = 5
  memory_size = 128

  depends_on = [
    aws_iam_role_policy.auditar_logs,
    aws_cloudwatch_log_group.auditar_chamado,
  ]
}

resource "aws_cloudwatch_event_target" "auditoria_para_lambda" {
  rule           = var.regra_auditoria_name
  event_bus_name = var.bus_name
  target_id      = "funcao-auditar-chamado"
  arn            = aws_lambda_function.auditar_chamado.arn
}

resource "aws_lambda_permission" "eventbridge_invoca_auditoria" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.auditar_chamado.function_name
  principal     = "events.amazonaws.com"
  source_arn    = var.regra_auditoria_arn
}
