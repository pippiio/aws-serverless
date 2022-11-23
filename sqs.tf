resource "aws_sqs_queue" "this" {
  for_each = local.config.queue

  name                      = each.key
  delay_seconds             = 90
  max_message_size          = 2048
  message_retention_seconds = 86400
  receive_wait_time_seconds = 10
  #   redrive_policy = jsonencode({
  #     deadLetterTargetArn = aws_sqs_queue.terraform_queue_deadletter.arn
  #     maxReceiveCount     = 4
  #   })

  tags = merge({}, local.default_tags)
}
