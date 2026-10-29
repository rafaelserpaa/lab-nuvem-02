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