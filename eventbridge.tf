resource "aws_cloudwatch_event_bus" "manutencao" {
  name = "manutencao"
}

resource "aws_cloudwatch_event_rule" "urgentes" {
  name           = "urgentes"
  description    = "Chamados urgentes vão para o tópico SNS do plantão"
  event_bus_name = aws_cloudwatch_event_bus.manutencao.name

  event_pattern = jsonencode({
    source        = ["campus.chamados"]
    "detail-type" = ["ChamadoRegistrado"]
    detail = {
      urgente = [true]
    }
  })
}

resource "aws_cloudwatch_event_target" "urgentes_para_sns" {
  rule           = aws_cloudwatch_event_rule.urgentes.name
  event_bus_name = aws_cloudwatch_event_bus.manutencao.name
  target_id      = "topico-chamados-urgentes"
  arn            = aws_sns_topic.chamados_urgentes.arn
}

resource "aws_cloudwatch_event_rule" "auditoria" {
  name           = "auditoria"
  description    = "Trilha de auditoria: todo evento da central de chamados"
  event_bus_name = aws_cloudwatch_event_bus.manutencao.name

  event_pattern = jsonencode({
    source = ["campus.chamados"]
  })
}

resource "aws_cloudwatch_event_target" "auditoria_para_lambda" {
  rule           = aws_cloudwatch_event_rule.auditoria.name
  event_bus_name = aws_cloudwatch_event_bus.manutencao.name
  target_id      = "funcao-auditar-chamado"
  arn            = aws_lambda_function.auditar_chamado.arn
}

resource "aws_lambda_permission" "eventbridge_invoca_auditoria" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.auditar_chamado.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.auditoria.arn
}