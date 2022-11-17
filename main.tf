locals {
  config = merge(defaults(var.config, {
    log_retention_in_days = 7
    }), {
    topic = { for idx, topic in coalesce(var.config.topic, {}) : idx => merge({ name = "${idx}${coalesce(topic.fifo, false) ? ".fifo" : ""}" }, topic) }
  })
  create_kms_key = local.config.kms_key_id == null ? 1 : 0
  kms_key_id     = try(one(aws_kms_key.this).arn, local.config.kms_key_id)
}

output "debug" {
  value = local.config
}