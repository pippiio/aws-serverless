data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

locals {
  name_prefix = var.name_prefix
  default_tags = merge(var.default_tags, {
    tf-module : "pippi.io/aws-serverless"
    tf-workspace = terraform.workspace
  })

  region_name = data.aws_region.current.name
  account_id  = data.aws_caller_identity.current.account_id

  kms_arn        = try(one(aws_kms_alias.this).arn, var.config.kms_arn)
  create_kms_key = var.config.kms_arn == null ? 1 : 0

  ecr_registry_uri = "${local.account_id}.dkr.ecr.${local.region_name}.amazonaws.com/"

  # https_endpoints = {
  #   for value in flatten([
  #     for func_name, func in local.config.function : [
  #       for http_key, endpoint in func.trigger.https : {
  #         func_name     = func_name
  #         endpoint_name = http_key
  #         endpoint      = endpoint
  #       }
  #     ]
  #   ]) : "${value.func_name}/${value.endpoint_name}" => value
  # }

  enable_rest_api_gateway = length(var.restapi.endpoints) > 0 ? 1 : 0
  # enable_rest_api_gateway = length(local.rest_endpoints) > 0 ? 1 : 0
  # rest_endpoints = {
  #   for value in flatten([
  #     for func_name, func in var.functions : [
  #       # for http_key, endpoint in func.trigger.rest : {
  #       for  endpoint in func.trigger.rest : {
  #         func_name     = func_name
  #         # endpoint_name = http_key
  #         endpoint      = endpoint
  #       }
  #     ]
  #   ]) : "${value.func_name}/${value.endpoint_name}" => value
  # }

  # binary_media_types = distinct(flatten([
  #   for func_name, func in local.config.function : flatten([
  #     for http_key, endpoint in func.trigger.rest :
  #        endpoint.binary_media_types != null ? endpoint.binary_media_types : []
  #     ])
  #   ])
  # )
}

resource "random_password" "this" {
  length  = 24
  special = true
}
