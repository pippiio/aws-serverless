data "aws_iam_policy_document" "assume_lambda" {
  for_each = local.config.function

  statement {
    sid     = "LambdaAssumeRole"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "function" {
  for_each = local.config.function

  statement {
    sid       = "CloudWatchLogs"
    resources = [aws_cloudwatch_log_group.function[each.key].arn]
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
  }
}

resource "aws_cloudwatch_log_group" "function" {
  for_each = local.config.function

  name              = "/aws/lambda/${var.name_prefix}${each.key}"
  retention_in_days = local.config.log_retention_in_days
  kms_key_id        = local.kms_alias_arn
  tags              = local.default_tags
}


resource "aws_iam_role" "function" {
  for_each = local.config.function

  name               = "${var.name_prefix}${each.key}"
  assume_role_policy = data.aws_iam_policy_document.assume_lambda[each.key].json

  inline_policy {
    name   = "LeastPrivilege"
    policy = data.aws_iam_policy_document.function[each.key].json
  }
}

resource "aws_lambda_function" "function" {
  for_each = local.config.function

  function_name = "${var.name_prefix}${each.key}"
  description   = each.value.description
  role          = aws_iam_role.function[each.key].arn

  s3_bucket = each.value.source.type == "s3" ? split(":", each.value.source.path)[0] : null
  s3_key    = each.value.source.type == "s3" ? split(":", each.value.source.path)[1] : null

  handler = each.value.source.handler
  runtime = each.value.source.runtime
}
