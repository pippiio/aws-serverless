# aws-serverless
The _aws-serverless_ is a generic Terraform module within the pippi.io family, maintained by Tech Chapter. The pippi.io modules are build to support common use cases often seen at Tech Chapters clients. They are created with best practices in mind and battle tested at scale. All modules are free and open-source under the Mozilla Public License Version 2.0.

The aws-serverless module is made to provision AWS Serverless resources.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.6.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 5.0 |
| <a name="requirement_null"></a> [null](#requirement\_null) | ~> 3.2.2 |
| <a name="requirement_random"></a> [random](#requirement\_random) | ~> 3.0 |

## Resources

| Name | Type |
|------|------|
| [aws_acm_certificate.restapi](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/acm_certificate) | resource |
| [aws_acm_certificate_validation.restapi](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/acm_certificate_validation) | resource |
| [aws_api_gateway_account.restapi](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_account) | resource |
| [aws_api_gateway_base_path_mapping.restapi](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_base_path_mapping) | resource |
| [aws_api_gateway_deployment.restapi](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_deployment) | resource |
| [aws_api_gateway_domain_name.restapi](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_domain_name) | resource |
| [aws_api_gateway_integration.restapi](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_integration) | resource |
| [aws_api_gateway_method.restapi](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_method) | resource |
| [aws_api_gateway_method_settings.restapi](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_method_settings) | resource |
| [aws_api_gateway_resource.level1](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_resource) | resource |
| [aws_api_gateway_resource.level2](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_resource) | resource |
| [aws_api_gateway_resource.level3](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_resource) | resource |
| [aws_api_gateway_resource.level4](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_resource) | resource |
| [aws_api_gateway_resource.level5](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_resource) | resource |
| [aws_api_gateway_resource.level6](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_resource) | resource |
| [aws_api_gateway_resource.level7](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_resource) | resource |
| [aws_api_gateway_resource.level8](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_resource) | resource |
| [aws_api_gateway_resource.level9](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_resource) | resource |
| [aws_api_gateway_rest_api.restapi](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_rest_api) | resource |
| [aws_api_gateway_stage.restapi](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_stage) | resource |
| [aws_cloudwatch_log_group.function](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_cloudwatch_log_group.restapi](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_ecr_pull_through_cache_rule.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecr_pull_through_cache_rule) | resource |
| [aws_iam_role.function](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.restapi](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_kms_alias.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_alias) | resource |
| [aws_kms_key.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_key) | resource |
| [aws_lambda_event_source_mapping.sqs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_event_source_mapping) | resource |
| [aws_lambda_function.function](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_function) | resource |
| [aws_lambda_permission.restapi](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_permission) | resource |
| [aws_s3_bucket.source](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket_public_access_block.source](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_public_access_block) | resource |
| [aws_s3_bucket_server_side_encryption_configuration.source](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_server_side_encryption_configuration) | resource |
| [aws_s3_bucket_versioning.source](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_versioning) | resource |
| [aws_s3_object.source](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_object) | resource |
| [aws_secretsmanager_secret.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret) | resource |
| [aws_secretsmanager_secret_version.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret_version) | resource |
| [aws_sns_topic.topic](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic) | resource |
| [aws_sns_topic_policy.topic](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic_policy) | resource |
| [aws_sns_topic_subscription.topic](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic_subscription) | resource |
| [aws_sqs_queue.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sqs_queue) | resource |
| [aws_sqs_queue_policy.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sqs_queue_policy) | resource |
| [aws_sqs_queue_redrive_policy.dead_letter_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sqs_queue_redrive_policy) | resource |
| [null_resource.docker_pull](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [random_password.this](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/password) | resource |
| [random_pet.source](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/pet) | resource |
| [archive_file.source](https://registry.terraform.io/providers/hashicorp/archive/latest/docs/data-sources/file) | data source |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_iam_policy_document.assume_lambda](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.assume_restapi](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.function](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.kms](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.queue](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.restapi](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.topic](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_kms_key.from_alias](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/kms_key) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |
| [aws_s3_object.function_source](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/s3_object) | data source |
| [aws_ssm_parameter.function](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ssm_parameter) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_config"></a> [config](#input\_config) | n/a | <pre>object({<br>    kms_arn                = optional(string)<br>    log_retention_in_days  = optional(number, 7)<br>  })</pre> | `{}` | no |
| <a name="input_container_registry_token"></a> [container\_registry\_token](#input\_container\_registry\_token) | Container registry token. | `string` | `null` | no |
| <a name="input_default_tags"></a> [default\_tags](#input\_default\_tags) | A map of default tags, that will be applied to all resources applicable. | `map(string)` | `{}` | no |
| <a name="input_function"></a> [function](#input\_function) | n/a | <pre>map(object({<br>    description        = optional(string)<br>    iam_role           = optional(string)<br>    timeout_seconds    = optional(number, 3)<br>    memory_size        = optional(number, 128)<br>    subnet_ids         = optional(set(string), [])<br>    security_group_ids = optional(set(string), [])<br>    iam_policies_arns  = optional(set(string))<br>    inline_policies    = optional(map(string), {})<br><br>    source = object({<br>      experimental_ecr_cache = optional(bool, false)<br><br>      type         = string # container, s3, local<br>      runtime      = optional(string)<br>      handler      = optional(string)<br>      architecture = optional(string, "x86_64")<br>      path         = string<br>      hash         = optional(string)<br>    })<br><br>    environment_variable = optional(map(object({<br>      type  = optional(string, "text") # text|ssm<br>      value = string<br>    })), {})<br><br>    trigger = optional(object({<br>      topic = optional(string)<br>      queue = optional(map(object({<br>        batch_size                         = optional(number, 5)<br>        maximum_batching_window_in_seconds = optional(number, 10)<br>      })), {})<br>      #     schedule<br>      # https = optional(map(object({<br>      #   method = string<br>      #   path   = string<br>      #   authorizer = optional(object({<br>      #     name             = string<br>      #     type             = optional(string, "JWT")<br>      #     identity_sources = optional(set(string))<br>      #     issuer_url       = optional(string)<br>      #     audience         = optional(set(string))<br>      #     scopes           = optional(set(string))<br>      #   }))<br>      # })), {})<br><br>      #     file<br>      #     log<br>      #     email<br>      #   loadbalancer<br>    }), {})<br><br>    target = optional(object({<br>      #   topic<br>      queue = optional(map(object({<br>        env_key = optional(string)<br>      })), {})<br>      #   function<br>    }), {})<br>  }))</pre> | n/a | yes |
| <a name="input_name_prefix"></a> [name\_prefix](#input\_name\_prefix) | A prefix that will be used on all named resources. | `string` | `"pippi-"` | no |
| <a name="input_queue"></a> [queue](#input\_queue) | n/a | <pre>map(object({<br>    public                     = bool<br>    visibility_timeout_seconds = optional(number, 30)<br>    message_retention_seconds  = optional(number, 86400)<br>    delay_seconds              = optional(number, 90)<br>    receive_wait_time_seconds  = optional(number, 10)<br><br>    dead_letter_queue = optional(object({<br>      name             = string<br>      max_recive_count = optional(number, 4)<br>    }), null)<br><br>    topic_subscriptions = optional(set(string))<br>  }))</pre> | `{}` | no |
| <a name="input_restapi"></a> [restapi](#input\_restapi) | n/a | <pre>object({<br>    domain     = optional(string)<br>    location   = optional(string, "regional") # regional, edge, private<br>    log_format = optional(string, "clf")<br><br>    endpoints = optional(set(object({<br>      method                = string<br>      path                  = string<br>      type                  = optional(string, "function") # mock, function, http<br>      target                = optional(string)<br>      loglevel              = optional(string, "info")<br>      throttling_rate_limit = optional(number, 100)<br>      authorizer = optional(object({<br>        name                  = string<br>        type                  = optional(string, "JWT") # token, request<br>        authorizer_cedentials = optional(string)<br>        ttl                   = optional(number, 60)<br>      }))<br>      binary_media_types = optional(list(string), [])<br>    })), [])<br>  })</pre> | `{}` | no |
| <a name="input_topic"></a> [topic](#input\_topic) | n/a | <pre>map(object({<br>    fifo            = optional(bool)<br>    delivery_policy = optional(string)<br>    policy          = optional(string)<br><br>    publisher = optional(map(object({<br>      type   = string<br>      values = set(string)<br>    })))<br><br>    subscriber = optional(map(object({<br>      protocol = string<br>      endpoint = string<br>    })))<br>  }))</pre> | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_kms_arn"></a> [kms\_arn](#output\_kms\_arn) | n/a |
| <a name="output_rest_api"></a> [rest\_api](#output\_rest\_api) | n/a |
<!-- END_TF_DOCS -->
