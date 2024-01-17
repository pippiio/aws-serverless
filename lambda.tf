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
    resources = ["${aws_cloudwatch_log_group.function[each.key].arn}:*"]
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    effect = "Allow"
  }

  statement {
    sid       = "KMS"
    resources = [data.aws_kms_key.from_alias.arn]
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey"
    ]
    effect = "Allow"
  }

  dynamic "statement" {
    for_each = length(each.value.trigger.queue) > 0 ? { enabled = true } : {}
    content {
      sid       = "SQSTriggers"
      resources = [for queue_key in keys(each.value.trigger.queue) : aws_sqs_queue.this[queue_key].arn]
      effect    = "Allow"
      actions = [
        "sqs:ReceiveMessage",
        "sqs:DeleteMessage",
        "sqs:GetQueueAttributes"
      ]
    }
  }

  dynamic "statement" {
    for_each = length(each.value.target.queue) > 0 ? { enabled = true } : {}
    content {
      sid       = "SQSTargets"
      resources = [for queue_key in keys(each.value.target.queue) : aws_sqs_queue.this[queue_key].arn]
      effect    = "Allow"
      actions   = ["sqs:SendMessage"]
    }
  }
}

resource "aws_cloudwatch_log_group" "function" {
  for_each = local.config.function

  name              = "/aws/lambda/${var.name_prefix}${each.key}"
  retention_in_days = local.config.log_retention_in_days
  kms_key_id        = local.kms_arn
  tags              = local.default_tags
}

resource "aws_lambda_permission" "rest" {
  for_each = local.enable_rest_api_gateway == 1 ? aws_lambda_function.function : {}

  action        = "lambda:InvokeFunction"
  function_name = each.value.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${split("/", one(aws_api_gateway_deployment.this).execution_arn)[0]}/*"
}

resource "aws_iam_role" "function" {
  for_each = local.config.function

  name               = "${var.name_prefix}lambda-${each.key}-role"
  assume_role_policy = data.aws_iam_policy_document.assume_lambda[each.key].json

  inline_policy {
    name   = "LeastPrivilege"
    policy = data.aws_iam_policy_document.function[each.key].json
  }

  dynamic "inline_policy" {
    for_each = each.value.inline_policies

    content {
      name   = "Custom${inline_policy.key}"
      policy = inline_policy.value
    }
  }
}

data "aws_s3_object" "function_source" {
  for_each = { for key, value in local.config.function : key => value if value.source.type == "s3" }
  bucket   = split("/", trimprefix(each.value.source.path, "s3://"))[0]
  key      = trimprefix(regexall("\\/.+$", trimprefix(each.value.source.path, "s3://"))[0], "/")
}

resource "aws_lambda_function" "function" {
  for_each = local.config.function

  function_name = "${var.name_prefix}${each.key}"
  description   = each.value.description
  role          = aws_iam_role.function[each.key].arn
  timeout       = each.value.timeout_seconds
  memory_size   = each.value.memory_size

  s3_bucket         = each.value.source.type == "s3" ? data.aws_s3_object.function_source[each.key].bucket : null
  s3_key            = each.value.source.type == "s3" ? data.aws_s3_object.function_source[each.key].key : null
  s3_object_version = each.value.source.type == "s3" ? data.aws_s3_object.function_source[each.key].version_id : null
  source_code_hash  = each.value.source.type == "s3" ? lookup(data.aws_s3_object.function_source[each.key].metadata, "hash", null) : each.value.source.hash

  publish = true

  handler = each.value.source.handler
  runtime = each.value.source.runtime

  kms_key_arn = length(each.value.environment_variable) > 0 ? data.aws_kms_key.from_alias.arn : null

  vpc_config {
    security_group_ids = each.value.security_group_ids
    subnet_ids         = each.value.subnet_ids
  }

  dynamic "environment" {
    for_each = try([
      merge(
        {
          for env_name, env_var in each.value.environment_variable :
          env_name => env_var.value
          if env_var.type == "text"
        },
        {
          for env_name, env_var in each.value.environment_variable :
          env_name => data.aws_ssm_parameter.function["${each.key}:${env_var.value}"].value
          if env_var.type == "ssm"
        },
        {
          for queue_name, queue in each.value.target.queue :
          queue.env_key => aws_sqs_queue.this[queue_name].url
          if queue.env_key != null
        }
      )
    ], [])

    content {
      variables = environment.value
    }
  }

  tags = local.default_tags
}

resource "aws_lambda_event_source_mapping" "sqs" {
  for_each = { for val in flatten([
    for func_name, func in local.config.function : [
      for queue_name, queue in func.trigger.queue : {
        func          = func_name
        queue         = queue_name
        batch_size    = queue.batch_size
        max_batch_sec = queue.maximum_batching_window_in_seconds
      }
    ]
  ]) : "${val.func}-${val.queue}" => val }

  function_name                      = aws_lambda_function.function[each.value.func].function_name
  event_source_arn                   = aws_sqs_queue.this[each.value.queue].arn
  batch_size                         = each.value.batch_size
  maximum_batching_window_in_seconds = each.value.max_batch_sec
}

data "aws_ssm_parameter" "function" {
  for_each = {
    for entry in flatten([
      for func_key, func in local.config.function : [
        for k, v in func.environment_variable : [{
          func_name = func_key
          var_name  = k
          ssm_name  = v.value
        }] if v.type == "ssm"
      ]
    ]) : "${entry.func_name}:${entry.var_name}" => entry.ssm_name
  }

  name            = each.value
  with_decryption = true
}
