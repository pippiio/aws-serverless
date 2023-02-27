output "sns-topics" {
  value = { for name, topic in aws_sns_topic.topic : name => topic.id }
}

output "kms_arn" {
  value = local.kms_arn
}

output "api_endpoint" {
  value = local.enable_api_gateway == 1 ? one(aws_apigatewayv2_api.this).api_endpoint : null
}

 output "secret" {
  value = {
    key   = "x-${local.name_prefix}secret"
    value = sensitive(random_password.this.result)
  }
  sensitive = true
}
