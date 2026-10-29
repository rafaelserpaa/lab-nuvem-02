data "archive_file" "registrar_chamado" {
  type        = "zip"
  source_file = "${path.module}/src/registrar_chamado.py"
  output_path = "${path.module}/build/registrar_chamado.zip"
}

resource "aws_cloudwatch_log_group" "registrar_chamado" {
  name              = "/aws/lambda/registrar-chamado"
  retention_in_days = 7
}

resource "aws_lambda_function" "registrar_chamado" {
  function_name = "registrar-chamado"
  description   = "Valida o chamado e publica ChamadoRegistrado no barramento manutencao"

  role    = aws_iam_role.registrar_chamado.arn
  handler = "registrar_chamado.lambda_handler"
  runtime = "python3.13"

  filename         = data.archive_file.registrar_chamado.output_path
  source_code_hash = data.archive_file.registrar_chamado.output_base64sha256

  timeout     = 5
  memory_size = 128

  environment {
    variables = {
      BUS_NAME = aws_cloudwatch_event_bus.manutencao.name
    }
  }

  depends_on = [
    aws_iam_role_policy.registrar_logs,
    aws_iam_role_policy.publicar_manutencao,
    aws_cloudwatch_log_group.registrar_chamado,
  ]
}