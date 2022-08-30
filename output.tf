output "serverless" {
  value = {
    kms_key_id = local.kms_key_id

    topic = { for name, topic in aws_sns_topic.topic : name => topic.id }
  }
}
