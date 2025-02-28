locals {
  endpoints = { for endpoint in var.restapi.endpoints : "${endpoint.path}/${endpoint.method}" => endpoint }

  rest_path = toset([for endpoint in var.restapi.endpoints : trimprefix(endpoint.path, "/")])

  all_paths = toset(flatten([
    for path in local.rest_path : [
      for idx in range(length(split("/", path))) :
      join("/", slice(split("/", path), 0, idx + 1))
  ]]))

  restapi_resources = merge(
    aws_api_gateway_resource.level1,
    aws_api_gateway_resource.level2,
    aws_api_gateway_resource.level3,
    aws_api_gateway_resource.level4,
    aws_api_gateway_resource.level5,
    aws_api_gateway_resource.level6,
    aws_api_gateway_resource.level7,
    aws_api_gateway_resource.level8,
    aws_api_gateway_resource.level9,
  )

  integration_type = {
    function = "AWS_PROXY"
    mock     = "MOCK"
  }

  log_format = {
    clf  = "$context.identity.sourceIp $context.identity.caller $context.identity.user [$context.requestTime] $context.httpMethod $context.resourcePath $context.protocol $context.status $context.responseLength $context.requestId $context.extendedRequestId"
    json = "{ 'requestId':'$context.requestId', 'extendedRequestId':'$context.extendedRequestId', 'ip': '$context.identity.sourceIp', 'caller':'$context.identity.caller', 'user':'$context.identity.user', 'requestTime':'$context.requestTime', 'httpMethod':'$context.httpMethod', 'resourcePath':'$context.resourcePath', 'status':'$context.status', 'protocol':'$context.protocol', 'responseLength':'$context.responseLength' }"
  }
}

data "aws_iam_policy_document" "assume_restapi" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["apigateway.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

data "aws_iam_policy_document" "restapi" {
  statement {
    effect = "Allow"

    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:DescribeLogGroups",
      "logs:DescribeLogStreams",
      "logs:PutLogEvents",
      "logs:GetLogEvents",
      "logs:FilterLogEvents",
    ]

    resources = ["*"] # todo
  }
}

resource "aws_cloudwatch_log_group" "restapi" {
  count             = local.enable_rest_api_gateway
  name              = "/aws/apigw/${aws_api_gateway_rest_api.restapi[0].id}/${local.name_prefix}deployment"
  retention_in_days = var.config.log_retention_in_days
  kms_key_id        = local.kms_arn
  tags              = local.default_tags
}

resource "aws_iam_role" "restapi" {
  count = local.enable_rest_api_gateway

  name               = "${var.name_prefix}api-gateway-role"
  assume_role_policy = data.aws_iam_policy_document.assume_restapi.json

  inline_policy {
    name   = "CloudWatchLeastPrivilege"
    policy = data.aws_iam_policy_document.restapi.json
  }
}

resource "aws_api_gateway_account" "restapi" {
  count = local.enable_rest_api_gateway

  cloudwatch_role_arn = aws_iam_role.restapi[0].arn
}

resource "aws_acm_certificate" "restapi" {
  count = var.restapi.domain != null ? 1 : 0

  domain_name       = var.restapi.domain
  validation_method = "DNS"

  tags = local.default_tags

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_acm_certificate_validation" "restapi" {
  count = var.restapi.domain != null ? 1 : 0

  certificate_arn = aws_acm_certificate.restapi[0].arn
}

resource "aws_api_gateway_rest_api" "restapi" {
  count = local.enable_rest_api_gateway

  name        = "${var.name_prefix}api-gw"
  description = "${var.name_prefix}api"

  disable_execute_api_endpoint = var.restapi.domain != null
  tags                         = local.default_tags

  endpoint_configuration {
    types = [upper(var.restapi.location)]
  }
}

resource "aws_api_gateway_resource" "level1" {
  for_each = { for path in local.all_paths : path => reverse(split("/", path))[0]
  if length(split("/", path)) == 1 }

  rest_api_id = aws_api_gateway_rest_api.restapi[0].id
  parent_id   = aws_api_gateway_rest_api.restapi[0].root_resource_id
  path_part   = each.value
}

resource "aws_api_gateway_resource" "level2" {
  for_each = { for path in local.all_paths : path => reverse(split("/", path))[0]
  if length(split("/", path)) == 2 }

  rest_api_id = aws_api_gateway_rest_api.restapi[0].id
  parent_id   = aws_api_gateway_resource.level1[trimsuffix(each.key, "/${each.value}")].id
  path_part   = each.value
}

resource "aws_api_gateway_resource" "level3" {
  for_each = { for path in local.all_paths : path => reverse(split("/", path))[0]
  if length(split("/", path)) == 3 }

  rest_api_id = aws_api_gateway_rest_api.restapi[0].id
  parent_id   = aws_api_gateway_resource.level2[trimsuffix(each.key, "/${each.value}")].id
  path_part   = each.value
}

resource "aws_api_gateway_resource" "level4" {
  for_each = { for path in local.all_paths : path => reverse(split("/", path))[0]
  if length(split("/", path)) == 4 }

  rest_api_id = aws_api_gateway_rest_api.restapi[0].id
  parent_id   = aws_api_gateway_resource.level3[trimsuffix(each.key, "/${each.value}")].id
  path_part   = each.value
}

resource "aws_api_gateway_resource" "level5" {
  for_each = { for path in local.all_paths : path => reverse(split("/", path))[0]
  if length(split("/", path)) == 5 }

  rest_api_id = aws_api_gateway_rest_api.restapi[0].id
  parent_id   = aws_api_gateway_resource.level4[trimsuffix(each.key, "/${each.value}")].id
  path_part   = each.value
}

resource "aws_api_gateway_resource" "level6" {
  for_each = { for path in local.all_paths : path => reverse(split("/", path))[0]
  if length(split("/", path)) == 6 }

  rest_api_id = aws_api_gateway_rest_api.restapi[0].id
  parent_id   = aws_api_gateway_resource.level5[trimsuffix(each.key, "/${each.value}")].id
  path_part   = each.value
}

resource "aws_api_gateway_resource" "level7" {
  for_each = { for path in local.all_paths : path => reverse(split("/", path))[0]
  if length(split("/", path)) == 7 }

  rest_api_id = aws_api_gateway_rest_api.restapi[0].id
  parent_id   = aws_api_gateway_resource.level6[trimsuffix(each.key, "/${each.value}")].id
  path_part   = each.value
}

resource "aws_api_gateway_resource" "level8" {
  for_each = { for path in local.all_paths : path => reverse(split("/", path))[0]
  if length(split("/", path)) == 8 }

  rest_api_id = aws_api_gateway_rest_api.restapi[0].id
  parent_id   = aws_api_gateway_resource.level7[trimsuffix(each.key, "/${each.value}")].id
  path_part   = each.value
}

resource "aws_api_gateway_resource" "level9" {
  for_each = { for path in local.all_paths : path => reverse(split("/", path))[0]
  if length(split("/", path)) == 9 }

  rest_api_id = aws_api_gateway_rest_api.restapi[0].id
  parent_id   = aws_api_gateway_resource.level8[trimsuffix(each.key, "/${each.value}")].id
  path_part   = each.value
}

resource "aws_api_gateway_method" "restapi" {
  for_each = local.endpoints

  rest_api_id          = aws_api_gateway_rest_api.restapi[0].id
  http_method          = each.value.method
  resource_id          = local.restapi_resources[trimprefix(each.value.path, "/")].id
  authorization        = try(each.value.authorizer.auth, "NONE")
  authorizer_id        = try(aws_api_gateway_authorizer.restapi[one(keys(aws_api_gateway_authorizer.restapi))].id, null)
  authorization_scopes = try(each.value.authorizer.scopes, null)
}

resource "aws_api_gateway_method_settings" "restapi" {
  for_each = local.endpoints

  rest_api_id = aws_api_gateway_rest_api.restapi[0].id
  stage_name  = aws_api_gateway_stage.restapi[0].stage_name
  method_path = each.key

  settings {
    metrics_enabled       = true
    logging_level         = upper(each.value.loglevel)
    throttling_rate_limit = each.value.throttling_rate_limit
  }
}

resource "aws_lambda_permission" "restapi" {
  for_each = toset([for endpoint in var.restapi.endpoints : endpoint.target if endpoint.type == "function"])

  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.function[each.value].function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${split("/", aws_api_gateway_deployment.restapi[0].execution_arn)[0]}/*"
}

resource "aws_api_gateway_integration" "restapi" {
  for_each = local.endpoints

  rest_api_id             = aws_api_gateway_rest_api.restapi[0].id
  resource_id             = local.restapi_resources[trimprefix(each.value.path, "/")].id
  http_method             = each.value.method
  type                    = local.integration_type[each.value.type]
  connection_type         = "INTERNET"
  integration_http_method = "POST"
  uri = {
    function = aws_lambda_function.function[each.value.target].invoke_arn
    mock     = null
  }[each.value.type]
}

resource "aws_api_gateway_deployment" "restapi" {
  count = local.enable_rest_api_gateway

  rest_api_id = aws_api_gateway_rest_api.restapi[0].id

  triggers = {
    redeployment = sha1(jsonencode([
      var.restapi.endpoints,
      aws_api_gateway_method.restapi,
      aws_api_gateway_method.cors,
      aws_api_gateway_integration.cors,
      aws_api_gateway_method_response.cors,
      aws_api_gateway_integration_response.cors,
      aws_api_gateway_gateway_response.response_4xx,
      aws_api_gateway_gateway_response.response_5xx
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [
    aws_api_gateway_integration.restapi
  ]
}

resource "aws_api_gateway_stage" "restapi" {
  count = local.enable_rest_api_gateway

  deployment_id = aws_api_gateway_deployment.restapi[0].id
  rest_api_id   = aws_api_gateway_rest_api.restapi[0].id
  stage_name    = "${local.name_prefix}deployment"

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.restapi[0].arn
    format          = try(local.log_format["clf"], var.restapi.log_format)
  }
}

resource "aws_api_gateway_domain_name" "restapi" {
  count = var.restapi.domain != null ? 1 : 0

  domain_name              = var.restapi.domain
  certificate_arn          = var.restapi.location == "edge" ? aws_acm_certificate.restapi[0].arn : null
  regional_certificate_arn = var.restapi.location == "regional" ? aws_acm_certificate.restapi[0].arn : null

  endpoint_configuration {
    types = [upper(var.restapi.location)]
  }
}

resource "aws_api_gateway_base_path_mapping" "restapi" {
  count = var.restapi.domain != null ? 1 : 0

  api_id      = aws_api_gateway_rest_api.restapi[0].id
  stage_name  = aws_api_gateway_stage.restapi[0].stage_name
  domain_name = aws_api_gateway_domain_name.restapi[0].domain_name
}

resource "aws_api_gateway_authorizer" "restapi" {
  for_each = { for key, value in {
    for auth in values(local.rest_endpoints)[*].endpoint.authorizer
    : auth.name => {
      for k, v in auth
      : k => v
      if v != null
    }... if auth != null
  } : key => merge(value...) }

  rest_api_id                      = aws_api_gateway_rest_api.restapi[0].id
  type                             = each.value.type
  authorizer_result_ttl_in_seconds = each.value.ttl
  name                             = each.key
  provider_arns                    = each.value.provider_arns
}



resource "aws_api_gateway_method" "cors" {
  for_each = local.restapi_resources

  rest_api_id   = aws_api_gateway_rest_api.restapi[0].id
  resource_id   = each.value.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "cors" {
  for_each = local.restapi_resources

  rest_api_id = aws_api_gateway_rest_api.restapi[0].id
  resource_id = each.value.id
  http_method = aws_api_gateway_method.cors[each.key].http_method
  type        = "MOCK"

  request_templates = {
    "application/json" = jsonencode(
      {
        statusCode = 200
      }
    )
  }

}

resource "aws_api_gateway_method_response" "cors" {
  for_each = local.restapi_resources

  rest_api_id = aws_api_gateway_rest_api.restapi[0].id
  resource_id = each.value.id
  http_method = aws_api_gateway_method.cors[each.key].http_method
  status_code = 200

  response_models = {
    "application/json" = "Empty"
  }

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin"  = var.restapi.cors_origin != null
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Headers" = true
  }
}

resource "aws_api_gateway_integration_response" "cors" {
  for_each = local.restapi_resources

  rest_api_id = aws_api_gateway_rest_api.restapi[0].id
  resource_id = each.value.id
  http_method = aws_api_gateway_method.cors[each.key].http_method
  status_code = 200

  //cors
  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin"  = "'${coalesce(var.restapi.cors_origin, "_")}'"
    "method.response.header.Access-Control-Allow-Methods" = "'GET,POST,OPTIONS,PUT,DELETE,PATCH'"
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,Authorization'"
  }
}

resource "aws_api_gateway_gateway_response" "response_4xx" {
  count = local.enable_rest_api_gateway

  rest_api_id   = aws_api_gateway_rest_api.restapi[0].id
  response_type = "DEFAULT_4XX"

  response_templates = {
    "application/json" = "{'message':$context.error.messageString}"
  }

  response_parameters = {
    "gatewayresponse.header.Access-Control-Allow-Origin" = "'${coalesce(var.restapi.cors_origin, "_")}'"
  }
}

resource "aws_api_gateway_gateway_response" "response_5xx" {
  count = local.enable_rest_api_gateway

  rest_api_id   = aws_api_gateway_rest_api.restapi[0].id
  response_type = "DEFAULT_5XX"

  response_templates = {
    "application/json" = "{'message':$context.error.messageString}"
  }

  response_parameters = {
    "gatewayresponse.header.Access-Control-Allow-Origin" = "'${coalesce(var.restapi.cors_origin, "_")}'"
  }
}
