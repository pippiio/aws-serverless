locals {
  config = var.config

  kms_arn        = try(one(aws_kms_alias.this).arn, local.config.kms_arn)
  create_kms_key = local.config.kms_arn == null ? 1 : 0

  endpoints_https = {
    for value in flatten([
      for func_name, func in local.config.function : [
        for http_key, endpoint in func.trigger.https : {
          func_name     = func_name
          endpoint_name = http_key
          endpoint      = endpoint
        }
      ]
    ]) : "${value.func_name}/${value.endpoint_name}" => value
  }
  endpoints_rest = {
    for value in flatten([
      for func_name, func in local.config.function : [
        for http_key, endpoint in func.trigger.rest : {
          func_name     = func_name
          endpoint_name = http_key
          endpoint      = endpoint
        }
      ]
    ]) : "${value.func_name}/${value.endpoint_name}" => value
  }

  enable_api_gateway_https = length(local.endpoints_https) > 0 ? 1 : 0
  enable_api_gateway_rest  = length(local.endpoints_rest) > 0 ? 1 : 0
}

resource "random_password" "this" {
  length  = 24
  special = true
}
