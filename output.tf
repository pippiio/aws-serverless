output "sns-topics" {
  value = { for name, topic in aws_sns_topic.topic : name => topic.id }
}

output "kms_arn" {
  value = local.kms_arn
}

output "https_api_endpoint" {
  value = local.enable_https_api_gateway == 1 ? one(aws_apigatewayv2_api.this).api_endpoint : null
}

output "rest_api_endpoint" {
  value = local.enable_rest_api_gateway == 1 ? one(aws_api_gateway_deployment.this).invoke_url : null
}

output "secret" {
  value = {
    key   = "x-${local.name_prefix}secret"
    value = sensitive(random_password.this.result)
  }
  sensitive = true
}

output "sqs_queue" {
  value = { for v in values(aws_sqs_queue.this) : trimprefix(v.name, local.name_prefix) => v }
}
