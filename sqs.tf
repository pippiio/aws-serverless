resource "aws_sqs_queue" "this" {
  for_each = var.queue

  name                       = "${var.name_prefix}${each.key}"
  delay_seconds              = each.value.delay_seconds
  max_message_size           = 2048
  message_retention_seconds  = each.value.message_retention_seconds
  receive_wait_time_seconds  = each.value.receive_wait_time_seconds
  visibility_timeout_seconds = each.value.visibility_timeout_seconds

  kms_master_key_id = local.kms_arn

  tags = merge({}, local.default_tags)
}

resource "aws_sqs_queue_policy" "this" {
  for_each = toset(keys(var.queue))

  queue_url = aws_sqs_queue.this[each.value].id
  policy    = data.aws_iam_policy_document.queue[each.value].json
}

resource "aws_sqs_queue_redrive_policy" "dead_letter_policy" {
  for_each = { for k, v in var.queue : k => v.dead_letter_queue if v.dead_letter_queue != null }

  queue_url = aws_sqs_queue.this[each.key].id
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.this[each.value.name].arn
    maxReceiveCount     = each.value.max_recive_count
  })
}

data "aws_iam_policy_document" "queue" {
  for_each = var.queue

  statement {
    sid       = "Enable IAM User Permissions"
    actions   = ["sqs:*"]
    resources = [aws_sqs_queue.this[each.key].arn]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${local.account_id}:root"]
    }
  }

  dynamic "statement" {
    // find all functions with target equal to current queue and return a list of all the functions keys
    for_each = flatten([for target_key, val in transpose({
      for func_key, func_val in var.function
      : func_key => keys(func_val.target.queue) })
      : val
      if target_key == each.key
    ])

    content {
      sid       = "Allow ${statement.value} Lambda SendMessage"
      actions   = ["sqs:SendMessage"]
      resources = [aws_sqs_queue.this[each.key].arn]

      principals {
        type        = "Service"
        identifiers = ["lambda.amazonaws.com"]
      }

      condition {
        test     = "ArnEquals"
        variable = "aws:SourceArn"
        values   = [aws_lambda_function.function[statement.value].arn]
      }
    }
  }
}
