resource "aws_api_gateway_rest_api" "this" {
  count = local.enable_api_gateway_rest

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
      for k, v in local.endpoints_rest : v.endpoint.path => {
        (split("/", v.endpoint.method)[0]) = {
          security = v.endpoint.authorizer != null ? [{
            (v.endpoint.authorizer.name) = []
          }] : null,
          x-amazon-apigateway-integration = {
            httpMethod           = "POST"
            payloadFormatVersion = "1.0"
            type                 = "AWS_PROXY"
            uri                  = aws_lambda_function.function[v.func_name].invoke_arn
          }
        }
      }
    }
    securityDefinitions = {
      for k, v in local.endpoints_rest : v.endpoint.path => {
        (v.endpoint.authorizer.name) : {
          type                         = "apiKey",
          name                         = "Authorization",
          in                           = "header",
          x-amazon-apigateway-authtype = "oauth2",
          x-amazon-apigateway-authorizer = {
            type                         = v.endpoint.authorizer.type,
            authorizerUri                = v.endpoint.authorizer.authorizer_uri,
            authorizerCredentials        = v.endpoint.authorizer.authorizer_cedentials,
            authorizerResultTtlInSeconds = v.endpoint.authorizer.ttl
          }
        }
      } if v.endpoint.authorizer != null
    }
  })
}

resource "aws_api_gateway_deployment" "this" {
  count = local.enable_api_gateway_rest

  rest_api_id = one(aws_api_gateway_rest_api.this).id

  triggers = {
    redeployment = sha1(jsonencode(one(aws_api_gateway_rest_api.this).body))
  }

  lifecycle {
    create_before_destroy = true
  }
}
