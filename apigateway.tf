resource "aws_apigatewayv2_api" "this" {
  count = length(local.endpoints) == 0 ? 0 : 1

  name          = "${var.name_prefix}api"
  protocol_type = "HTTP"
  tags          = local.default_tags
}

resource "aws_apigatewayv2_stage" "this" {
  count = length(local.endpoints) == 0 ? 0 : 1

  api_id = aws_apigatewayv2_api.this[0].id

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
}

resource "aws_apigatewayv2_integration" "this" {
  for_each = {
    for i, endpoint in local.endpoints : i => endpoint
  }

  api_id      = aws_apigatewayv2_api.this[0].id
  description = "Endpoint integration for ${aws_lambda_function.this[each.value.func_name].name} lambda"

  integration_uri    = aws_lambda_function.this[each.value.func_name].invoke_arn
  integration_type   = "AWS_PROXY"
  integration_method = "POST"
  timeout_milliseconds = aws_lambda
}

resource "aws_apigatewayv2_route" "this" {
  for_each = {
    for i, endpoint in local.endpoints : i => endpoint
  }

  api_id = aws_apigatewayv2_api.this[0].id

  route_key = "${each.value.method} ${each.value.route}"
  target    = "integrations/${aws_apigatewayv2_integration.this[each.key].id}"
}

resource "aws_lambda_permission" "api_gateway" {
  for_each = {
    for i, endpoint in local.endpoints : i => endpoint
  }

  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.this[each.value.func_name].function_name

  principal  = "apigateway.amazonaws.com"
  source_arn = "${aws_apigatewayv2_api.this[0].execution_arn}/${aws_apigatewayv2_stage.this[0].name}/${each.value.method}${each.value.route}"
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