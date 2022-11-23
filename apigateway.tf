resource "aws_apigatewayv2_api" "this" {
  count = length(local.endpoints) == 0 ? 0 : 1

  name          = "${var.name_prefix}api"
  protocol_type = "HTTP"
  tags          = local.default_tags
}

resource "aws_apigatewayv2_stage" "this" {
  count = length(local.endpoints) == 0 ? 0 : 1

  api_id = one(aws_apigatewayv2_api.this).id

  name        = "$default"
  auto_deploy = true

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gateway[0].arn

    format = jsonencode({
      requestId               = "$context.requestId"
      sourceIp                = "$context.identity.sourceIp"
      requestTime             = "$context.requestTime"
      protocol                = "$context.protocol"
      httpMethod              = "$context.httpMethod"
      resourcePath            = "$context.resourcePath"
      routeKey                = "$context.routeKey"
      status                  = "$context.status"
      responseLength          = "$context.responseLength"
      integrationErrorMessage = "$context.integrationErrorMessage"
    })
  }

  tags = local.default_tags
}

resource "aws_apigatewayv2_integration" "this" {
  for_each = {
    for func_name, func in local.config.function : func_name => func
  }

  api_id = one(aws_apigatewayv2_api.this).id
  description = "Endpoint integration for ${each.key} lambda"

  integration_uri    = aws_lambda_function.function[each.key].invoke_arn
  integration_type   = "AWS_PROXY"
  integration_method = "POST"
}

resource "aws_apigatewayv2_route" "this" {
  for_each = {
    for i, endpoint in local.endpoints : i => endpoint
  }

  api_id = one(aws_apigatewayv2_api.this).id

  route_key = "${each.value.endpoint.method} ${each.value.endpoint.path}"
  target    = "integrations/${aws_apigatewayv2_integration.this[each.value.func_name].id}"
}

locals {
  endpoints = flatten([
    for func_name, func in local.config.function : [
      for http_key, endpoint in func.trigger.https : {
        func_name     = func_name
        endpoint_name = http_key
        endpoint = endpoint
      }
    ]
  ])
}

resource "aws_cloudwatch_log_group" "api_gateway" {
  count = length(local.endpoints) == 0 ? 0 : 1

  name              = "/aws/api_gateway/${aws_apigatewayv2_api.this[0].name}"
  retention_in_days = local.config.log_retention_in_days
  kms_key_id        = local.kms_alias_arn

  tags = local.default_tags
}
