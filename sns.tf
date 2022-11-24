data "aws_iam_policy_document" "topic" {
  for_each = { for idx, topic in local.config.topic : idx => topic.publisher if try(length(topic.publisher) > 0, false) }

  dynamic "statement" {
    for_each = { for idx, publisher in each.value : idx => publisher if publisher.type == "account" }

    content {
      sid       = statement.key
      actions   = ["sns:Publish"]
      resources = ["arn:aws:sns:${local.region_name}:${local.account_id}:${var.name_prefix}${each.key}"]

      principals {
        type        = "AWS"
        identifiers = statement.value.values
      }
    }
  }

  dynamic "statement" {
    for_each = { for idx, publisher in each.value : idx => publisher if publisher.type == "organization" }

    content {
      sid       = statement.key
      actions   = ["sns:Publish"]
      resources = ["arn:aws:sns:${local.region_name}:${local.account_id}:${var.name_prefix}${each.key}"]

      principals {
        type        = "AWS"
        identifiers = ["*"]
      }

      condition {
        test     = "StringEquals"
        variable = "aws:PrincipalOrgID"
        values   = statement.value.values
      }
    }
  }

  dynamic "statement" {
    for_each = { for idx, publisher in each.value : idx => publisher if publisher.type == "service" }

    content {
      sid       = statement.key
      actions   = ["sns:Publish"]
      resources = ["arn:aws:sns:${local.region_name}:${local.account_id}:${var.name_prefix}${each.key}"]

      principals {
        type        = "AWS"
        identifiers = ["*"]
      }

      condition {
        test     = "StringEquals"
        variable = "aws:SourceAccount"
        values   = [local.account_id]
      }
    }
  }

  dynamic "statement" {
    for_each = { for idx, publisher in each.value : idx => publisher if publisher.type == "arn" }

    content {
      sid       = statement.key
      actions   = ["sns:Publish"]
      resources = ["arn:aws:sns:${local.region_name}:${local.account_id}:${var.name_prefix}${each.key}"]

      principals {
        type        = "AWS"
        identifiers = ["*"]
      }

      condition {
        test     = "ArnLike"
        variable = "aws:SourceArn"
        values   = statement.value.values
      }
    }
  }
}

resource "aws_sns_topic" "topic" {
  for_each = local.config.topic

  name                        = format("${var.name_prefix}${each.key}%s", coalesce(each.value.fifo, false) ? ".fifo" : "")
  display_name                = title(replace(each.key, "/[-_]+/", " "))
  kms_master_key_id           = local.kms_arn
  fifo_topic                  = coalesce(each.value.fifo, false)
  content_based_deduplication = coalesce(each.value.fifo, false)
  policy                      = each.value.policy
  delivery_policy             = each.value.delivery_policy
  tags                        = local.default_tags
}

resource "aws_sns_topic_policy" "topic" {
  for_each = data.aws_iam_policy_document.topic

  arn    = aws_sns_topic.topic[each.key].arn
  policy = each.value.json
}

resource "aws_sns_topic_subscription" "topic" {
  // For each topic's subscription
  for_each = { for entry in flatten([for topic_idx, topic in local.config.topic : [for subscriber_idx, subscriber in topic.subscriber : {
    topic_idx      = topic_idx
    subscriber_idx = subscriber_idx
    subscriber     = subscriber
  }] if topic.subscriber != null]) : "${entry.topic_idx}/${entry.subscriber_idx}" => entry }

  topic_arn            = aws_sns_topic.topic[each.value.topic_idx].arn
  protocol             = each.value.subscriber.protocol
  endpoint             = each.value.subscriber.endpoint
  raw_message_delivery = !contains(["lambda", "email", "sms"], each.value.subscriber.protocol)
}
