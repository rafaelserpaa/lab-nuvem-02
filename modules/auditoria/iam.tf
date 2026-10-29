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
