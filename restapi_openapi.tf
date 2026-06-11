locals {
  restapi_default_endpoint_key          = try(sort(keys(local.endpoints))[0], null)
  restapi_default_loglevel              = try(local.endpoints[local.restapi_default_endpoint_key].loglevel, "info")
  restapi_default_throttling_rate_limit = try(local.endpoints[local.restapi_default_endpoint_key].throttling_rate_limit, 100)
  restapi_method_setting_overrides = {
    for key, endpoint in local.endpoints : key => endpoint
    if upper(endpoint.loglevel) != upper(local.restapi_default_loglevel) || endpoint.throttling_rate_limit != local.restapi_default_throttling_rate_limit
  }

  restapi_endpoint_paths = toset([
    for endpoint in var.restapi.endpoints : endpoint.path
  ])

  restapi_paths_with_options = toset([
    for endpoint in var.restapi.endpoints : endpoint.path
    if upper(endpoint.method) == "OPTIONS"
  ])

  restapi_authorizers = {
    for key, value in {
      for endpoint in var.restapi.endpoints :
      endpoint.authorizer.name => endpoint.authorizer...
      if endpoint.authorizer != null
    } : key => merge(value...)
  }

  restapi_security_schemes = {
    for name, authorizer in local.restapi_authorizers :
    name => merge(
      {
        type                         = "apiKey"
        name                         = "Authorization"
        in                           = "header"
        x-amazon-apigateway-authtype = upper(authorizer.auth) == "AWS_IAM" ? "awsSigv4" : lower(authorizer.auth) == "cognito_user_pools" ? "cognito_user_pools" : lower(authorizer.auth)
      },
      jsondecode(upper(authorizer.auth) == "AWS_IAM" ? "{}" : jsonencode({
        x-amazon-apigateway-authorizer = merge(
          {
            type = upper(authorizer.auth) == "COGNITO_USER_POOLS" ? "cognito_user_pools" : lower(authorizer.type)
          },
          jsondecode(try(authorizer.provider_arns, null) != null ? jsonencode({
            providerARNs = tolist(authorizer.provider_arns)
          }) : "{}"),
          jsondecode(try(authorizer.lambda_arn, null) != null ? jsonencode({
            authorizerUri = "arn:aws:apigateway:${local.region_name}:lambda:path/2015-03-31/functions/${authorizer.lambda_arn}/invocations"
          }) : "{}"),
          jsondecode(try(authorizer.authorizer_cedentials, null) != null ? jsonencode({
            authorizerCredentials = authorizer.authorizer_cedentials
          }) : "{}"),
          jsondecode(try(authorizer.ttl, null) != null ? jsonencode({
            authorizerResultTtlInSeconds = authorizer.ttl
          }) : "{}")
        )
      }))
    )
  }

  restapi_openapi_operations = {
    for endpoint in var.restapi.endpoints :
    "${endpoint.path}/${endpoint.method}" => merge(
      {
        responses = {
          "200" = {
            description = "OK"
          }
        }
      },
      jsondecode(endpoint.authorizer != null ? jsonencode({
        security = [
          {
            (endpoint.authorizer.name) = try(endpoint.authorizer.scopes, null) != null ? tolist(endpoint.authorizer.scopes) : []
          }
        ]
      }) : "{}"),
      {
        x-amazon-apigateway-integration = jsondecode(endpoint.type == "mock" ? jsonencode({
          type = "mock"
          requestTemplates = {
            "application/json" = jsonencode({ statusCode = 200 })
          }
          responses = {
            default = {
              statusCode = "200"
            }
          }
          }) : jsonencode({
          type       = "aws_proxy"
          httpMethod = "POST"
          uri        = aws_lambda_function.function[endpoint.target].invoke_arn
        }))
      }
    )
  }

  restapi_openapi_cors_operation = {
    responses = {
      "200" = {
        description = "CORS support"
        headers = {
          "Access-Control-Allow-Origin" = {
            schema = { type = "string" }
          }
          "Access-Control-Allow-Methods" = {
            schema = { type = "string" }
          }
          "Access-Control-Allow-Headers" = {
            schema = { type = "string" }
          }
        }
      }
    }
    x-amazon-apigateway-integration = {
      type = "mock"
      requestTemplates = {
        "application/json" = jsonencode({ statusCode = 200 })
      }
      responses = {
        default = {
          statusCode = "200"
          responseParameters = {
            "method.response.header.Access-Control-Allow-Origin"  = "'${coalesce(var.restapi.cors_origin, "_")}'"
            "method.response.header.Access-Control-Allow-Methods" = "'GET,POST,OPTIONS,PUT,DELETE,PATCH'"
            "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,Authorization'"
          }
        }
      }
    }
  }

  restapi_openapi_paths = {
    for path in local.restapi_endpoint_paths :
    path => merge(
      jsondecode(var.restapi.cors_origin != null && !contains(local.restapi_paths_with_options, path) ? jsonencode({
        options = local.restapi_openapi_cors_operation
      }) : "{}"),
      merge([
        for endpoint in var.restapi.endpoints :
        {
          (upper(endpoint.method) == "ANY" ? "x-amazon-apigateway-any-method" : lower(endpoint.method)) = local.restapi_openapi_operations["${endpoint.path}/${endpoint.method}"]
        }
        if endpoint.path == path
      ]...)
    )
  }

  restapi_gateway_responses = {
    DEFAULT_4XX = {
      responseParameters = {
        "gatewayresponse.header.Access-Control-Allow-Origin" = "'${coalesce(var.restapi.cors_origin, "_")}'"
      }
      responseTemplates = {
        "application/json" = "{'message':$context.error.messageString}"
      }
    }
    DEFAULT_5XX = {
      responseParameters = {
        "gatewayresponse.header.Access-Control-Allow-Origin" = "'${coalesce(var.restapi.cors_origin, "_")}'"
      }
      responseTemplates = {
        "application/json" = "{'message':$context.error.messageString}"
      }
    }
  }

  restapi_openapi = merge(
    {
      openapi = "3.0.1"
      info = {
        title   = "${var.name_prefix}api-gw"
        version = "1.0"
      }
      paths = local.restapi_openapi_paths
    },
    jsondecode(length(local.restapi_security_schemes) > 0 ? jsonencode({
      components = {
        securitySchemes = local.restapi_security_schemes
      }
    }) : "{}"),
    jsondecode(var.restapi.cors_origin != null ? jsonencode({
      x-amazon-apigateway-gateway-responses = local.restapi_gateway_responses
    }) : "{}")
  )

  restapi_openapi_body = jsonencode(local.restapi_openapi)
}
