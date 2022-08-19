# data "aws_iam_policy_document" "kms" {
#   statement {
#     resources = ["*"]
#     actions   = ["kms:*"]

#     principals {
#       type        = "AWS"
#       identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.id}:root"]
#     }
#   }

#   statement {
#     effect    = "Allow"
#     resources = ["*"]
#     actions   = ["kms:*"]

#     principals {
#       type        = "Service"
#       identifiers = ["eks.amazonaws.com"]
#     }
#   }
# }

# resource "aws_kms_key" "cluster" {
#   description         = "KMS CMK used by eks cluster."
#   enable_key_rotation = true
#   policy              = data.aws_iam_policy_document.kms.json

#   tags = merge(local.default_tags, {
#     "Name" = "${local.name_prefix}eks-kms"
#   })
# }

# resource "aws_kms_alias" "cluster" {
#   name          = "alias/${local.name_prefix}eks-cluster-kms-cmk"
#   target_key_id = aws_kms_key.cluster.key_id
# }

# # Kubernetes Secret KMS Key
# data "aws_iam_policy_document" "k8s" {
#   statement {
#     resources   = ["*"]
#     not_actions = ["kms:Decrypt"]

#     principals {
#       type        = "AWS"
#       identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.id}:root"]
#     }
#   }

#   statement {
#     resources = ["*"]
#     actions   = ["kms:Decrypt"]

#     principals {
#       type        = "AWS"
#       identifiers = compact([data.aws_iam_session_context.current.issuer_arn, local.config.administrator_role_arn])
#     }
#   }
# }

# resource "aws_kms_key" "k8s" {
#   description         = "KMS CMK used To create kubernetes secrets"
#   enable_key_rotation = true
#   policy              = data.aws_iam_policy_document.k8s.json

#   tags = merge(local.default_tags, {
#     "Name" = "${local.name_prefix}k8s-secret-kms"
#   })
# }

# resource "aws_kms_alias" "k8s" {
#   name          = "alias/${local.name_prefix}k8s-secret-kms"
#   target_key_id = aws_kms_key.k8s.key_id
# }
