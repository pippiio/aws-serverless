output "sns-topics" {
  value = { for name, topic in aws_sns_topic.topic : name => topic.id }
}

output "kms_alias_arn" {
  value = local.kms_alias_arn
}