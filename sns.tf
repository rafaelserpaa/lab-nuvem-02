resource "aws_sns_topic" "chamados_urgentes" {
  name = "chamados-urgentes"
}

resource "aws_sns_topic_subscription" "plantao_email" {
  topic_arn = aws_sns_topic.chamados_urgentes.arn
  protocol  = "email"
  endpoint  = var.email_plantao
}

data "aws_iam_policy_document" "politica_topico" {
  statement {
    sid    = "dono-do-topico"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = [data.aws_caller_identity.atual.account_id]
    }

    actions = [
      "SNS:Publish",
      "SNS:Subscribe",
      "SNS:GetTopicAttributes",
      "SNS:SetTopicAttributes",
      "SNS:ListSubscriptionsByTopic",
      "SNS:DeleteTopic",
    ]

    resources = [aws_sns_topic.chamados_urgentes.arn]
  }

  statement {
    sid    = "eventbridge-publica"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }

    actions   = ["sns:Publish"]
    resources = [aws_sns_topic.chamados_urgentes.arn]

    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"
      values   = [aws_cloudwatch_event_rule.urgentes.arn]
    }
  }
}

resource "aws_sns_topic_policy" "chamados_urgentes" {
  arn    = aws_sns_topic.chamados_urgentes.arn
  policy = data.aws_iam_policy_document.politica_topico.json
}