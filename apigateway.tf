resource "aws_apigatewayv2_api" "this" {
  count = local.enable_api_gateway

  name          = "${var.name_prefix}api"
  protocol_type = "HTTP"
  tags          = local.default_tags
}

resource "aws_apigatewayv2_stage" "this" {
  count = local.enable_api_gateway

  api_id = one(aws_apigatewayv2_api.this).id

  name        = "$default"
  auto_deploy = true

  access_log_settings {
    destination_arn = one(aws_cloudwatch_log_group.api_gateway).arn

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
    if length(func.trigger.https) > 0
  }

  api_id      = one(aws_apigatewayv2_api.this).id
  description = "Endpoint integration for ${each.key} lambda"

  integration_uri    = aws_lambda_function.function[each.key].invoke_arn
  integration_type   = "AWS_PROXY"
  integration_method = "POST"

  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "this" {
  for_each = local.endpoints

  api_id = one(aws_apigatewayv2_api.this).id

  route_key = "${each.value.endpoint.method} ${each.value.endpoint.path}"
  target    = "integrations/${aws_apigatewayv2_integration.this[each.value.func_name].id}"

  authorizer_id = each.value.endpoint.authorizer != null ? aws_apigatewayv2_authorizer.this[each.value.endpoint.authorizer.name].id : null
  authorization_type = each.value.endpoint.authorizer != null ? "JWT" : null
  authorization_scopes = try(each.value.endpoint.authorizer.type, "") == "JWT" ? each.value.endpoint.authorizer.scopes : null
}

resource "aws_lambda_permission" "api_gateway" {
  for_each = local.endpoints

  statement_id  = "AllowExecutionFromAPIGateway_${each.value.func_name}_${each.value.endpoint_name}"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.function[each.value.func_name].function_name

  principal  = "apigateway.amazonaws.com"
  source_arn = "${one(aws_apigatewayv2_api.this).execution_arn}/${one(aws_apigatewayv2_stage.this).name}/${each.value.endpoint.method}${each.value.endpoint.path}"
}

resource "aws_cloudwatch_log_group" "api_gateway" {
  count = local.enable_api_gateway

  name              = "/aws/api_gateway/${aws_apigatewayv2_api.this[0].name}"
  retention_in_days = local.config.log_retention_in_days
  kms_key_id        = local.kms_arn

  tags = local.default_tags
}

resource "aws_apigatewayv2_authorizer" "this" {
  for_each = { for key, value in { 
    for auth in values(local.endpoints)[*].endpoint.authorizer 
    : auth.name => { 
      for k, v in auth 
      : k => v 
      if v != null
    }... if auth != null 
  } : key => merge(value...) }

  api_id = one(aws_apigatewayv2_api.this).id
  authorizer_type = "JWT"
  identity_sources = each.value.identity_sources
  name = each.key

  jwt_configuration {
    audience = each.value.audience
    issuer = each.value.issuer_url
  }
}
