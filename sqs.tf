resource "aws_sqs_queue" "this" {
  for_each = local.config.queue

  name                       = "${var.name_prefix}${each.key}"
  delay_seconds              = each.value.delay_seconds
  max_message_size           = 2048
  message_retention_seconds  = each.value.message_retention_seconds
  receive_wait_time_seconds  = each.value.receive_wait_time_seconds
  visibility_timeout_seconds = each.value.visibility_timeout_seconds
  #   redrive_policy = jsonencode({
  #     deadLetterTargetArn = aws_sqs_queue.terraform_queue_deadletter.arn
  #     maxReceiveCount     = 4
  #   })

  kms_master_key_id = local.kms_arn
  policy            = data.aws_iam_policy_document.queue[each.key].json

  tags = merge({}, local.default_tags)
}


data "aws_iam_policy_document" "queue" {
  for_each = local.config.queue

  statement {
    sid       = "Enable IAM User Permissions"
    actions   = ["sqs:*"]
    resources = ["arn:aws:sqs:${local.region_name}:${local.account_id}:${local.name_prefix}${each.key}"]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${local.account_id}:root"]
    }
  }

  dynamic "statement" {
    // find all functions with target equal current queue and return a distinct list of all the function keys keys
    for_each = flatten([for target_key, val in transpose({
      for func_key, func_val in local.config.function
      : func_key => keys(func_val.target.queue) })
      : val
      if target_key == each.key
    ])

    content {
      sid       = "Allow ${statement.value} Lambda SendMessage"
      actions   = ["sqs:SendMessage"]
      resources = ["arn:aws:sqs:${local.region_name}:${local.account_id}:${var.name_prefix}${each.key}"]

      principals {
        type        = "Service"
        identifiers = ["lambda.amazonaws.com"]
      }

      condition {
        test     = "ArnEquals"
        variable = "aws:SourceArn"
        values   = ["arn:aws:lambda:${local.region_name}:${local.account_id}:${local.name_prefix}${statement.value}"]
      }
    }
  }

}