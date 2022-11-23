locals {
  config = var.config
  create_kms_key = local.config.kms_alias_arn == null ? 1 : 0
  kms_alias_arn     = try(one(aws_kms_alias.this).arn, local.config.kms_alias_arn)
}