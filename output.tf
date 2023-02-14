output "sns-topics" {
  value = { for name, topic in aws_sns_topic.topic : name => topic.id }
}

output "kms_arn" {
  value = local.kms_arn
}

output "api_endpoint" {
  value = local.enable_api_gateway == 1 ? aws_apigatewayv2_api.this.api_endpoint : null
}
