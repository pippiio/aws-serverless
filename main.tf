locals {
  config = var.config
  create_kms_key = local.config.kms_key_id == null ? 1 : 0
  kms_key_id     = try(one(aws_kms_key.this).arn, local.config.kms_key_id)
}

output "debug" {
  value = local.config
}