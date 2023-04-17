resource "aws_api_gateway_rest_api" "this" {
  count = local.enable_rest_api_gateway

  name = "${var.name_prefix}rest-api"

  endpoint_configuration {
    types = ["REGIONAL"]
  }

  body = jsonencode({
    openapi = "3.0.1"
    info = {
      title   = "${var.name_prefix}rest-api"
      version = "1.0"
    }
    paths = {
      for k, v in local.rest_endpoints : (replace(v.endpoint.path, "/${local.rest_stage_name}", "")) => {
        lower(v.endpoint.method) = {
          security = v.endpoint.authorizer != null ? [{
            (v.endpoint.authorizer.name) = []
          }] : null,
          x-amazon-apigateway-integration = {
            httpMethod           = "POST"
            payloadFormatVersion = "1.0"
            type                 = "AWS_PROXY"
            uri                  = aws_lambda_function.function[v.func_name].invoke_arn
          }
          x-amazon-apigateway-binary-media-types = v.endpoint.binary_media_types
        }
      }
    }
    securityDefinitions = {
      for k, v in local.rest_endpoints : v.endpoint.authorizer.name => {
        type                         = "apiKey",
        name                         = "Authorization",
        in                           = "header",
        x-amazon-apigateway-authtype = "oauth2",
        x-amazon-apigateway-authorizer = {
          type                         = v.endpoint.authorizer.type,
          authorizerUri                = aws_lambda_function.function[v.func_name].invoke_arn,
          authorizerCredentials        = v.endpoint.authorizer.authorizer_cedentials,
          authorizerResultTtlInSeconds = v.endpoint.authorizer.ttl
        }
      } if v.endpoint.authorizer != null
    }
  })
}

resource "aws_api_gateway_deployment" "this" {
  count = local.enable_rest_api_gateway

  rest_api_id = one(aws_api_gateway_rest_api.this).id

  triggers = {
    redeployment = sha1(jsonencode(one(aws_api_gateway_rest_api.this).body))
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "this" {
  count = local.enable_rest_api_gateway

  deployment_id = one(aws_api_gateway_deployment.this).id
  rest_api_id   = one(aws_api_gateway_rest_api.this).id
  stage_name    = local.rest_stage_name
}
