output "bus_name" {
  value = aws_cloudwatch_event_bus.manutencao.name
}

output "bus_arn" {
  value = aws_cloudwatch_event_bus.manutencao.arn
}

output "regra_urgentes_name" {
  value = aws_cloudwatch_event_rule.urgentes.name
}

output "regra_urgentes_arn" {
  value = aws_cloudwatch_event_rule.urgentes.arn
}

output "regra_auditoria_name" {
  value = aws_cloudwatch_event_rule.auditoria.name
}

output "regra_auditoria_arn" {
  value = aws_cloudwatch_event_rule.auditoria.arn
}
