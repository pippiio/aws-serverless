data "aws_s3_object" "source" {
  for_each = { for key, value in var.functions : key => value if value.source.type == "s3" }
  
  bucket   = split("/", trimprefix(each.value.source.path, "s3://"))[0]
  key      = trimprefix(regexall("\\/.+$", trimprefix(each.value.source.path, "s3://"))[0], "/")
}

data "archive_file" "source" {
  for_each = { for function, config in var.config.function : function => config.source.path if config.source.type == "local" }

  type        = "zip"
  source_dir  = each.value
  output_path = "${each.key}.zip"
}

locals {
  enable_source_bucket = length(data.archive_file.source) > 0 ? 1 : 0
}

resource "random_pet" "source" {
  keepers = {
    account = local.region_name
    region  = local.account_id
    name    = local.name_prefix
  }
}

resource "aws_s3_bucket" "source" {
  count = local.enable_source_bucket

  bucket        = "${local.name_prefix}source-${random_pet.source.id}"
  force_destroy = true
  tags          = local.default_tags
}

resource "aws_s3_bucket_versioning" "source" {
  count = local.enable_source_bucket

  bucket = aws_s3_bucket.source[0].bucket
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "source" {
  count = local.enable_source_bucket

  bucket = aws_s3_bucket.source[0].bucket

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = local.kms_arn
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "source" {
  count = local.enable_source_bucket

  bucket = aws_s3_bucket.source[0].bucket

  ignore_public_acls      = true
  block_public_acls       = true
  block_public_policy     = true
  restrict_public_buckets = true
}

resource "aws_s3_object" "source" {
  for_each = { for function, config in var.config.function : function => config.source.path if config.source.type == "local" }

  bucket                 = aws_s3_bucket.source[0].bucket
  key                    = "${each.key}.zip"
  source                 = data.archive_file.source[each.key].output_path
  etag                   = filemd5(data.archive_file.source[each.key].output_path)
  server_side_encryption = "aws:kms"

  lifecycle {
    create_before_destroy = true
  }
}
