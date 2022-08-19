output "debug_config" {
  value = local.config
}

output "sqs_arn" {
  value = [for k, v in aws_sqs_queue.this : v.arn]
}

output "sqs_arn_alt" {
  value = aws_sqs_queue.this
}