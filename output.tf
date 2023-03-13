output "sns-topics" {
  value = { for name, topic in aws_sns_topic.topic : name => topic.id }
}

output "kms_arn" {
  value = local.kms_arn
}

output "api_endpoint_https" {
  value = local.enable_api_gateway_https == 1 ? one(aws_apigatewayv2_api.this).api_endpoint : null
}

output "api_endpoint_rest" {
  value = local.enable_api_gateway_rest == 1 ? one(aws_api_gateway_deployment.this).invoke_url : null
}

output "secret" {
  value = {
    key   = "x-${local.name_prefix}secret"
    value = sensitive(random_password.this.result)
  }
  sensitive = true
}
