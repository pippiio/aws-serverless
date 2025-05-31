resource "aws_lambda_permission" "apigw_invoke_authorizer" {
  count = var.custom_authorizer_function != null ? 1 : 0

  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.function[var.custom_authorizer_function].function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${split("/", aws_api_gateway_deployment.restapi[0].execution_arn)[0]}/*"
}

resource "aws_lambda_function" "lambda_authorizer" {
  count = var.custom_authorizer_function != null ? 1 : 0

  function_name = "${var.name_prefix}authorizer"
  description   = var.custom_authorizer_function.description
  role          = aws_iam_role.restapi[0].arn
  timeout       = var.custom_authorizer_function.timeout_seconds
  memory_size   = var.custom_authorizer_function.memory_size

  s3_bucket = try({
    "s3"    = try(data.aws_s3_object.function_source[var.custom_authorizer_function].bucket, null)
    "local" = try(aws_s3_bucket.source[0].bucket, null)
  }[var.custom_authorizer_function.source.type], null)
  s3_key = try({
    "s3"    = try(data.aws_s3_object.function_source[var.custom_authorizer_function].key, null)
    "local" = try(aws_s3_object.source[var.custom_authorizer_function].key, null)
  }[var.custom_authorizer_function.source.type], null)
  source_code_hash = var.custom_authorizer_function.source.type == "s3" ? lookup(data.aws_s3_object.function_source[var.custom_authorizer_function].metadata, "hash", null) : var.custom_authorizer_function.source.hash

  handler = var.custom_authorizer_function.source.handler
  runtime = var.custom_authorizer_function.source.runtime

  kms_key_arn = length(var.custom_authorizer_function.environment_variable) > 0 ? data.aws_kms_key.from_alias.arn : null

  vpc_config {
    security_group_ids = var.custom_authorizer_function.security_group_ids
    subnet_ids         = var.custom_authorizer_function.subnet_ids
  }

  dynamic "environment" {
    for_each = try([
      merge(
        { for env_name, env_var in var.custom_authorizer_function.environment_variable :
          env_name => env_var.value
          if env_var.type == "text"
        },
        {
          for env_name, env_var in var.custom_authorizer_function.environment_variable :
          env_name => data.aws_ssm_parameter.function["${var.custom_authorizer_function.name}:${env_var.value}"].value
          if env_var.type == "ssm"
        },
      )
    ], [])

    content {
      variables = environment.value
    }
  }

  tags = local.default_tags

  depends_on = [aws_s3_object.source]
}


