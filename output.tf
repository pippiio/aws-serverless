output "serverless" {
  value = {
    kms_key_id = local.kms_key_id

    topic = { for idx, topic in aws_sns_topic.topic : idx => topic.id }
    queue = { for idx, queue in aws_sqs_queue.queue : idx => queue.id }
  }
}
