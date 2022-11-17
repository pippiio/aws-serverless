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
  kms_key_id        = local.kms_key_id
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
  architectures = [coalesce(each.value.source.architecture, "x86_64")]

  #   filename      = "lambda_function_payload.zip"
  #   handler       = "index.test"

  #   # The filebase64sha256() function is available in Terraform 0.11.12 and later
  #   # For Terraform 0.11.11 and earlier, use the base64sha256() function and the file() function:
  #   # source_code_hash = "${base64sha256(file("lambda_function_payload.zip"))}"
  #   source_code_hash = filebase64sha256("lambda_function_payload.zip")

  #   runtime = "nodejs12.x"

  #   environment {
  #     variables = {
  #       foo = "bar"
  #     }
  #   }

  # #   package_type  = "Image"
  # #   function_name = "${var.name_prefix}${each.key}"
  # #   role          = aws_iam_role.function[each.key].arn
  # #   description   = each.value.description
  # #   image_uri     = "${aws_ecr_repository.registry[each.key].repository_url}:${each.value.image_tag}"
  # #   kms_key_arn   = aws_kms_key.this.arn
  # #   memory_size   = each.value.memory_size
  # #   timeout       = each.value.timeout
  # #   publish       = false
  # #   tags          = var.default_tags

  # #   dynamic "environment" {
  # #     for_each = { for k, v in local.env_vars : k => v if k == each.key }

  # #     content {
  # #       variables = environment.value
  # #     }
  # #   }
}
