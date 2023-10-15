locals {
  enable_code_build = length([for config in values(var.config.function) : 1 if contains(["git", "local"], config.source.type)]) > 0 ? 1 : 0
}

data "aws_iam_policy_document" "build_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type = "Service"
      identifiers = [
        "codebuild.amazonaws.com",
        "codepipeline.amazonaws.com",
      ]
    }

    actions = ["sts:AssumeRole"]
  }
}

data "aws_iam_policy_document" "build_inline_policy" {
  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]
    resources = [for grp in aws_cloudwatch_log_group.build : "${grp.arn}:*"]
  }

  statement {
    effect    = "Allow"
    actions   = ["s3:*"]
    resources = flatten([for bucket in aws_s3_bucket.source : [bucket.arn, "${bucket.arn}/*"]])
  }

  statement {
    effect    = "Allow"
    actions   = ["codebuild:StartBuild"]
    resources = [for function, config in var.config.function : "arn:aws:codebuild:${local.region_name}:${local.account_id}:project/${var.name_prefix}${function}-build" if "local" == config.source.type]
  }
}

resource "aws_iam_role" "build" {
  count = local.enable_code_build

  name               = "${var.name_prefix}build-role"
  assume_role_policy = data.aws_iam_policy_document.build_assume_role.json

  inline_policy {
    name   = "LeastPrivilege"
    policy = data.aws_iam_policy_document.build_inline_policy.json
  }
}

resource "aws_cloudwatch_log_group" "build" {
  count = local.enable_code_build

  name              = "/aws/codebuild/${local.name_prefix}build"
  retention_in_days = var.config.log_retention_in_days
  kms_key_id        = local.kms_arn
  tags              = local.default_tags
}

resource "aws_codebuild_project" "build" {
  for_each = { for function, config in var.config.function : function => {
    type    = config.source.type
    path    = config.source.path
    engine  = regex("^[a-z]+", config.source.runtime)
    version = trimsuffix(regex("[0-9\\.]+", config.source.runtime), ".")
  } if contains(["git", "local"], config.source.type) }

  name           = "${var.name_prefix}${each.key}-build"
  description    = "Build ${var.name_prefix}${each.key} "
  build_timeout  = "60"
  service_role   = aws_iam_role.build[0].arn
  encryption_key = local.kms_arn

  artifacts {
    type = "CODEPIPELINE"
    # type           = "S3"
    # location       = aws_s3_bucket.source[0].bucket
    # path           = "artifact/"
    # namespace_type = "NONE"
    # name           = "${each.key}.zip"
    # packaging      = "ZIP"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/amazonlinux2-x86_64-standard:4.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
  }

  logs_config {
    cloudwatch_logs {
      group_name  = aws_cloudwatch_log_group.build[0].name
      stream_name = each.key
    }
  }

  source {
    type                = each.value.type == "local" ? "CODEPIPELINE" : upper(each.value.type)
    location            = each.value.type == "local" ? null : each.value.path
    report_build_status = contains(["github", "bitbucket"], each.value.type) ? true : null

    buildspec = templatefile("${path.module}/buildspec/${each.value.engine}.yml", {
      version = each.value.version
    })
  }

  tags = local.default_tags
}

resource "aws_codepipeline" "build" {
  for_each = aws_s3_object.source

  # { for function, config in var.config.function : function => config.source.path if config.source.type == "local" }

  name     = "${var.name_prefix}${each.key}-pipeline"
  role_arn = aws_iam_role.build[0].arn

  artifact_store {
    location = each.value.bucket
    type     = "S3"
  }

  stage {
    name = "Source"
    action {
      name             = "SourceAction"
      category         = "Source"
      owner            = "AWS"
      provider         = "S3"
      version          = "1"
      output_artifacts = ["source_output"]

      configuration = {
        S3Bucket    = each.value.bucket
        S3ObjectKey = "${each.key}.zip"
      }
    }
  }

  stage {
    name = "Build"
    action {
      name             = "BuildAction"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["source_output"]
      output_artifacts = ["build_output"]
      version          = "1"

      configuration = {
        ProjectName = aws_codebuild_project.build[each.key].name
      }
    }
  }
}