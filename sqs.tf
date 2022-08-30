data "aws_iam_policy_document" "queue" {
  for_each = local.config.queue

  statement {
    sid       = "Enable IAM User Permissions"
    actions   = ["sqs:*"]
    resources = ["arn:aws:sqs:${local.region_name}:${local.account_id}:${var.name_prefix}${each.key}"]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${local.account_id}:root"]
    }
  }

  dynamic "statement" {
    for_each = [for topic in coalesce(each.value.topic_subscriptions, []) : topic]

    content {
      sid       = "Allow ${local.name_prefix}${statement.value} SNS SendMessage"
      actions   = ["sqs:SendMessage"]
      resources = ["arn:aws:sqs:${local.region_name}:${local.account_id}:${var.name_prefix}${each.key}"]

      principals {
        type        = "Service"
        identifiers = ["sns.amazonaws.com"]
      }

      condition {
        test     = "ArnEquals"
        variable = "aws:SourceArn"
        values   = [substr(statement.value, 0, 4) == "arn:" ? statement.value : aws_sns_topic.topic[statement.value].arn]
      }
    }
  }
}

resource "aws_sqs_queue" "queue" {
  for_each = local.config.queue

  name                        = format("${var.name_prefix}${each.key}%s", coalesce(each.value.fifo, false) ? ".fifo" : "")
  fifo_queue                  = coalesce(each.value.fifo, false)
  content_based_deduplication = coalesce(each.value.fifo, false)
  kms_master_key_id           = local.kms_key_id
  policy                      = data.aws_iam_policy_document.queue[each.key].json

  visibility_timeout_seconds = each.value.visibility_timeout_seconds
  message_retention_seconds  = each.value.message_retention_seconds
  delay_seconds              = each.value.delay_seconds
  receive_wait_time_seconds  = each.value.receive_wait_time_seconds

  # redrive_policy - (Optional) The JSON policy to set up the Dead Letter Queue, see AWS docs. Note: when specifying maxReceiveCount, you must specify it as an integer (5), and not a string ("5").
  # redrive_allow_policy - (Optional) The JSON policy to set up the Dead Letter Queue redrive permission, see AWS docs.

  tags = merge({}, local.default_tags)
}

resource "aws_sns_topic_subscription" "queue" {
  for_each = { for entry in flatten([for idx, queue in local.config.queue : [for topic in queue.topic_subscriptions : {
    queue = idx
    topic = topic
  } if substr(topic, 0, 4) != "arn:"] if queue.topic_subscriptions != null]) : "${entry.queue}/${entry.topic}" => entry }

  protocol             = "sqs"
  topic_arn            = aws_sns_topic.topic[each.value.topic].arn
  endpoint             = aws_sqs_queue.queue[each.value.queue].arn
  raw_message_delivery = true
}
