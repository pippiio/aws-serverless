data "aws_iam_policy_document" "kms" {
  statement {
    sid       = "Enable IAM User Permissions"
    resources = ["*"]
    actions   = ["kms:*"]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${local.account_id}:root"]
    }
  }

  statement {
    sid       = "Allow Lambda CloudWatch Logs"
    resources = ["*"]
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey"
    ]

    principals {
      type        = "Service"
      identifiers = ["logs.${local.region_name}.amazonaws.com"]
    }

    condition {
      test     = "ArnEquals"
      variable = "kms:EncryptionContext:aws:logs:arn"
      values   = [for function in keys(local.config.function) : "arn:aws:logs:${local.region_name}:${local.account_id}:log-group:/aws/lambda/${var.name_prefix}${function}"]
    }
  }

  statement {
    sid       = "Allow SNS"
    resources = ["*"]
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey"
    ]

    principals {
      type = "Service"
      identifiers = [
        "sns.amazonaws.com",
        # "lambda.amazonaws.com",

      ]
    }

    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"
      values = setunion(
        [for topic in values(local.config.topic) : "arn:aws:sns:${local.region_name}:${local.account_id}:${var.name_prefix}${topic.name}"],
        # [for function in keys(local.config.function) : "arn:aws:sns:${local.region_name}:${local.account_id}:${var.name_prefix}${function}"],
      )
    }
  }
}

resource "aws_kms_key" "this" {
  count = local.create_kms_key

  description         = "KMS CMK used by ${var.name_prefix}serverless"
  enable_key_rotation = true
  policy              = data.aws_iam_policy_document.kms.json
  tags = merge(var.default_tags, {
    "Name" = "${var.name_prefix}kms-cmk"
  })
}

resource "aws_kms_alias" "this" {
  count = local.create_kms_key

  name          = "alias/${var.name_prefix}serverless-cmk"
  target_key_id = one(aws_kms_key.this).key_id
}
