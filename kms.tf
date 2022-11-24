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
      type        = "Service"
      identifiers = ["sns.amazonaws.com"]
    }

    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"
      values   = ["arn:aws:sns:${local.region_name}:${local.account_id}:${local.name_prefix}*"]
    }
  }

  statement {
    sid       = "Allow Lambda"
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
      identifiers = ["lambda.amazonaws.com"]
    }

    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"
      values   = ["arn:aws:lambda:${local.region_name}:${local.account_id}:${local.name_prefix}*"]
    }
  }

  statement {
    sid       = "Allow CloudWatch Logs"
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
      values   = ["arn:aws:logs:${local.region_name}:${local.account_id}:log-group:/aws/*/${local.name_prefix}*"]
    }
  }
}

resource "aws_kms_key" "this" {
  count = local.create_kms_key

  description         = "KMS CMK used by ${local.name_prefix}serverless"
  enable_key_rotation = true
  policy              = data.aws_iam_policy_document.kms.json
  tags = merge(local.default_tags, {
    "Name" = "${local.name_prefix}kms-cmk"
  })
}

resource "aws_kms_alias" "this" {
  count = local.create_kms_key

  name          = "alias/${local.name_prefix}serverless-cmk"
  target_key_id = one(aws_kms_key.this).key_id
}

data "aws_kms_key" "from_alias" {
  key_id = local.kms_arn
}