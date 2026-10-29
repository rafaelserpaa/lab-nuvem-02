resource "aws_apigatewayv2_api" "chamados" {
  name          = "chamados-api"
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_integration" "registrar_chamado" {
  api_id = aws_apigatewayv2_api.chamados.id

  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.registrar_chamado.invoke_arn
  payload_format_version = "2.0"
  timeout_milliseconds   = 10000
}

resource "aws_apigatewayv2_route" "post_chamados" {
  api_id    = aws_apigatewayv2_api.chamados.id
  route_key = "POST /chamados"
  target    = "integrations/${aws_apigatewayv2_integration.registrar_chamado.id}"
}

resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.chamados.id
  name        = "$default"
  auto_deploy = true
}

resource "aws_lambda_permission" "api_invoca_registrar" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.registrar_chamado.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.chamados.execution_arn}/*/POST/chamados"
}