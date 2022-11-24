locals {
  config         = var.config
  
  kms_arn  = try(one(aws_kms_alias.this).arn, local.config.kms_arn)
  create_kms_key = local.config.kms_arn == null ? 1 : 0

  endpoints = flatten([
    for func_name, func in local.config.function : [
      for http_key, endpoint in func.trigger.https : {
        func_name     = func_name
        endpoint_name = http_key
        endpoint      = endpoint
      }
    ]
  ])
  enable_api_gateway = length(local.endpoints) > 0 ? 1 : 0
}