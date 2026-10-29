data "aws_iam_policy_document" "lambda_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "registrar_chamado" {
  name               = "registrar-chamado-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

data "aws_iam_policy_document" "registrar_logs" {
  statement {
    sid    = "escreverLogsDaPropriaFuncao"
    effect = "Allow"

    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    resources = ["${aws_cloudwatch_log_group.registrar_chamado.arn}:*"]
  }
}

resource "aws_iam_role_policy" "registrar_logs" {
  name   = "escrever-logs"
  role   = aws_iam_role.registrar_chamado.id
  policy = data.aws_iam_policy_document.registrar_logs.json
}

data "aws_iam_policy_document" "publicar_manutencao" {
  statement {
    sid       = "publicarSomenteNoBarramentoManutencao"
    effect    = "Allow"
    actions   = ["events:PutEvents"]
    resources = [aws_cloudwatch_event_bus.manutencao.arn]
  }
}

resource "aws_iam_role_policy" "publicar_manutencao" {
  name   = "publicar-manutencao"
  role   = aws_iam_role.registrar_chamado.id
  policy = data.aws_iam_policy_document.publicar_manutencao.json
}

resource "aws_iam_role" "auditar_chamado" {
  name               = "auditar-chamado-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

data "aws_iam_policy_document" "auditar_logs" {
  statement {
    effect    = "Allow"
    actions   = ["logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["${aws_cloudwatch_log_group.auditar_chamado.arn}:*"]
  }
}

resource "aws_iam_role_policy" "auditar_logs" {
  name   = "escrever-logs"
  role   = aws_iam_role.auditar_chamado.id
  policy = data.aws_iam_policy_document.auditar_logs.json
}