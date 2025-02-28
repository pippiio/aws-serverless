# output "sns-topics" {
#   value = { for name, topic in aws_sns_topic.topic : name => topic.id }
# }

output "kms_arn" {
  value = local.kms_arn
}

output "rest_api" {
  value = {
    execution_arn  = try(aws_api_gateway_rest_api.restapi[0].execution_arn, null)
    invoke_url     = try(var.restapi.domain != null ? "https://${var.restapi.domain}/" : aws_api_gateway_stage.restapi[0].invoke_url, null)
    domain_name    = try(aws_api_gateway_domain_name.restapi[0].regional_domain_name, null)
    api_gateway_id = aws_api_gateway_rest_api.restapi[0].id
    stage_name     = aws_api_gateway_stage.restapi[0].stage_name
  }
}

# output "https_api_endpoint" {
#   value = local.enable_https_api_gateway == 1 ? one(aws_apigatewayv2_api.this).api_endpoint : null
# }

# output "rest_api_endpoint" {
#   value = local.enable_rest_api_gateway == 1 ? one(aws_api_gateway_deployment.this).invoke_url : null
# }

# output "secret" {
#   value = {
#     key   = "x-${local.name_prefix}secret"
#     value = sensitive(random_password.this.result)
#   }
#   sensitive = true
# }

# output "sqs_queue" {
#   value = { for v in values(aws_sqs_queue.this) : trimprefix(v.name, local.name_prefix) => v }
# }
