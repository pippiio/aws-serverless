data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

locals {
  name_prefix = var.name_prefix
  config      = var.config
  default_tags = merge(var.default_tags, {
    tf-module : "pippi.io/aws-serverless"
    tf-workspace = terraform.workspace
  })

  region_name = data.aws_region.current.name
  account_id  = data.aws_caller_identity.current.account_id

  kms_arn        = try(one(aws_kms_alias.this).arn, local.config.kms_arn)
  create_kms_key = local.config.kms_arn == null ? 1 : 0

  https_endpoints = {
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

  rest_endpoints = {
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

  enable_https_api_gateway = length(local.https_endpoints) > 0 ? 1 : 0
  enable_rest_api_gateway  = length(local.rest_endpoints) > 0 ? 1 : 0

  rest_stage_name = local.enable_rest_api_gateway == 1 ? (split("/", values(local.rest_endpoints)[0].endpoint.path)[1]) : null
}

resource "random_password" "this" {
  length  = 24
  special = true
}
