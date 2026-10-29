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

resource "aws_cloudwatch_event_rule" "auditoria" {
  name           = "auditoria"
  description    = "Trilha de auditoria: todo evento da central de chamados"
  event_bus_name = aws_cloudwatch_event_bus.manutencao.name

  event_pattern = jsonencode({
    source = ["campus.chamados"]
  })
}
