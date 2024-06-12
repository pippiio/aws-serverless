locals {
  container_uris = {
    for function_key, function in var.function :
    function_key => function.source.path
    if function.source.type == "container"
    && length(regexall("^[0-9]+.*", function.source.path)) == 0
  }

  container_image_paths = {
    for function_key, function in var.function :
    function_key => regexall("(\\.[a-z]{1,3})\\/(.*)", function.source.path)[0][1]
  }

  container_registry_regex = "^(([a-z,1-9,-]*\\.)?[a-z]*\\.[a-z]{1,3})\\/"
}

resource "aws_ecr_pull_through_cache_rule" "this" {
  for_each = local.container_uris

  ecr_repository_prefix = each.key
  upstream_registry_url = regexall(local.container_registry_regex, each.value)[0][0]
  credential_arn        = contains(["registry-1.docker.io", "ghcr.io"], regexall(local.container_registry_regex, each.value)[0][0]) ? aws_secretsmanager_secret.this[each.key].arn : null

  depends_on = [aws_secretsmanager_secret_version.this]
}

resource "aws_secretsmanager_secret" "this" {
  for_each = {
    for key, path in local.container_uris :
    key => path
    if contains(["registry-1.docker.io", "ghcr.io"], regexall(local.container_registry_regex, path)[0][0])
  }

  name = "ecr-pullthroughcache/${each.key}"

  recovery_window_in_days = 7
}

resource "aws_secretsmanager_secret_version" "this" {
  for_each = aws_secretsmanager_secret.this

  secret_id     = each.value.id
  secret_string = jsonencode({ "username" : "docker", "accessToken" : var.container_registry_token })
}

resource "null_resource" "docker_pull" {
  for_each = local.container_uris

  triggers = {
    image = each.value
  }

  provisioner "local-exec" {
    command = "docker pull ${local.ecr_registry_uri}${aws_ecr_pull_through_cache_rule.this[each.key].ecr_repository_prefix}/${local.container_image_paths[each.key]} && docker image rm ${local.ecr_registry_uri}${aws_ecr_pull_through_cache_rule.this[each.key].ecr_repository_prefix}/${local.container_image_paths[each.key]}"
  }
}
