variable "name_prefix" {
  description = "A prefix that will be used on all named resources."
  type        = string
  default     = "pippi-"

  validation {
    condition     = length(regexall("^[a-zA-Z-]*$", var.name_prefix)) > 0
    error_message = "`name_prefix` must satisfy pattern `^[a-zA-Z-]+$`."
  }
}

variable "default_tags" {
  description = "A map of default tags, that will be applied to all resources applicable."
  type        = map(string)
  default     = {}
}

variable "config" {
  type = object({
    kms_arn               = optional(string)
    log_retention_in_days = optional(number, 7)
  })
  default = {}
}

variable "function" {
  type = map(object({
    description        = optional(string)
    iam_role           = optional(string)
    timeout_seconds    = optional(number, 3)
    memory_size        = optional(number, 128)
    subnet_ids         = optional(set(string), [])
    security_group_ids = optional(set(string), [])
    iam_policies_arns  = optional(set(string))
    inline_policies    = optional(map(string), {})

    source = object({
      type         = string # ecr, s3, local
      runtime      = string
      handler      = string
      architecture = optional(string, "x86_64")
      path         = string
      hash         = optional(string)
    })

    environment_variable = optional(map(object({
      type  = optional(string, "text") # text|ssm
      value = string
    })), {})

    trigger = optional(object({
      topic = optional(string)
      queue = optional(map(object({
        batch_size                         = optional(number, 5)
        maximum_batching_window_in_seconds = optional(number, 10)
      })), {})
      #     schedule
      # https = optional(map(object({
      #   method = string
      #   path   = string
      #   authorizer = optional(object({
      #     name             = string
      #     type             = optional(string, "JWT")
      #     identity_sources = optional(set(string))
      #     issuer_url       = optional(string)
      #     audience         = optional(set(string))
      #     scopes           = optional(set(string))
      #   }))
      # })), {})

      #     file
      #     log
      #     email
      #   loadbalancer
    }), {})

    target = optional(object({
      #   topic
      queue = optional(map(object({
        env_key = optional(string)
      })), {})
      #   function
    }), {})
  }))

  validation {
    error_message = "Invalid source type. Valid values includes [s3, ecr, local]."
    condition     = try(alltrue(flatten([for function in values(var.function) : contains(["s3", "ecr", "local"], function.source.type)])), true)
  }

  validation {
    error_message = "Invalid path for s3 source. The path must be a valid s3 uri (s3:// can be omited). E.g. 's3://bucket_name/key/to/object' or 'bucket_name/key/to/object'."
    condition     = try(alltrue(flatten([for function in values(var.function) : length(regexall("^(s3:\\/\\/)?[\\w\\-]+\\/.+$", function.source.path)) > 0 if function.source.type == "s3"])), true)
  }

  validation {
    error_message = "Invalid source architecture. Valid values includes [x86_64, arm64]."
    condition     = try(alltrue(flatten([for function in values(var.function) : contains(["x86_64", "arm64"], function.source.architecture)])), true)
  }

  validation {
    error_message = "Invalid environment variable type. Valid values includes [text, ssm]"
    condition     = try(alltrue(flatten([for function in values(var.function) : [for env_var in values(function.environment_variable) : contains(["text", "ssm"], env_var.type)]])), true)
  }
}

variable "restapi" {
  type = object({
    domain      = optional(string)
    location    = optional(string, "regional") # regional, edge, private
    log_format  = optional(string, "clf")
    cors_origin = optional(string)

    endpoints = optional(set(object({
      method                = string
      path                  = string
      edp_name              = string
      type                  = optional(string, "function") # mock, function, http
      target                = optional(string)
      loglevel              = optional(string, "info")
      throttling_rate_limit = optional(number, 100)
      authorizer = optional(object({
        auth                  = string # CUSTOM, AWS_IAM, COGNITO_USER_POOLS
        name                  = string
        type                  = optional(string, "TOKEN") # token, request, COGNITO_USER_POOLS
        authorizer_cedentials = optional(string)
        ttl                   = optional(number, 60)
        lambda_arn            = optional(string)
        provider_arns         = optional(set(string))
        scopes                = optional(set(string)) # only if auth = COGNITO_USER_POOLS
      }))
      binary_media_types = optional(list(string), [])
    })), [])
  })
  default = {}

  #   firewall = optional(object({
  #     block_by_default = optional(bool, false)

  #     aws_managed_rules = optional(map(object({
  #       rule_action_override = optional(map(string), {})
  #       })), {
  #       AWSManagedRulesAmazonIpReputationList = {},
  #       AWSManagedRulesCommonRuleSet          = {}
  #     })

  #     blocked_ip_cidrs  = optional(set(string), [])
  #     blocked_countries = optional(set(string), [])
  #     allowed_ip_cidrs  = optional(set(string), [])
  #     allowed_countries = optional(set(string), [])
  #     rule_groups       = optional(map(string), {})
  #   }), {})
  # })
}

variable "cron" {
  type = map(object({
    schedule_exp = string
  }))
  default = {}
}

variable "topic" {
  type = map(object({
    fifo            = optional(bool)
    delivery_policy = optional(string)
    policy          = optional(string)

    publisher = optional(map(object({
      type   = string
      values = set(string)
    })))

    subscriber = optional(map(object({
      protocol = string
      endpoint = string
    })))
  }))
  default = {}

  validation {
    error_message = "Topic names can include alphanumeric characters, hyphens (-) and underscores."
    condition     = try(alltrue([for name in keys(var.topic) : length(regexall("^[a-zA-Z0-9_-]+$", name)) > 0]), true)
  }

  validation {
    error_message = "Topic policy and publisher are mutually exclusive."
    condition     = try(alltrue([for topic in values(var.topic) : !(topic.policy != null && topic.publisher != null)]), true)
  }
}

variable "queue" {
  type = map(object({
    public                     = bool
    visibility_timeout_seconds = optional(number, 30)
    message_retention_seconds  = optional(number, 86400)
    delay_seconds              = optional(number, 90)
    receive_wait_time_seconds  = optional(number, 10)

    dead_letter_queue = optional(object({
      name             = string
      max_recive_count = optional(number, 4)
    }), null)

    topic_subscriptions = optional(set(string))
  }))
  default = {}
}

# variable "config" {
#   type = object({

#     # storage = optional(map(object({})))

#     # database = optional(map(object({})))

#     function = optional(map(object({



#   ##### Firewall #####

#   validation {
#     error_message = "Invalid rule action type. Valid values includes [allow, block, captcha, count]."
#     condition     = try(alltrue(flatten([for rule in values(var.config.firewall.aws_managed_rules) : [for action in values(rule.rule_action_override) : contains(["allow", "block", "captcha", "count"], action)] if rule.rule_action_override != null])), true)
#   }

#   ##### .subscriber #####

#   validation {
#     error_message = "Invalid subscriber protocol. Valid values includes [lambda, email, email-json, sms, http, https]."
#     condition     = try(alltrue(flatten([for topic in values(var.config.topic) : [for subscriber in values(topic.subscriber) : contains(["lambda", "email", "email-json", "sms", "http", "https", "sqs"], subscriber.protocol)] if topic.subscriber != null])), true)
#   }

#   validation {
#     error_message = "Only sqs subscriber protocol can be used with FIFO topics."
#     condition     = try(alltrue(flatten([for topic in values(var.config.topic) : [for subscriber in values(topic.subscriber) : subscriber.protocol == "sqs"] if coalesce(topic.fifo, false)])), true)
#   }

#   ##### .publisher #####

#   validation {
#     error_message = "Invalid publisher type. Valid values includes [service, account, organization, arn]."
#     condition     = try(alltrue(flatten([for topic in values(var.config.topic) : [for publisher in values(topic.publisher) : contains(["service", "account", "organization", "arn"], publisher.type)] if topic.publisher != null])), true)
#   }

#   ##### Function #####

#   ##### .trigger.https #####

#   validation {
#     error_message = "Invalid http method. Valid values includes [GET, POST, PUT, DELETE, PATCH]"
#     condition     = try(alltrue(flatten([for function in values(var.config.function) : [for endpoint in values(function.trigger.https) : contains(["GET", "POST", "PUT", "DELETE", "PATCH"], endpoint.method)]])), true)
#   }

#   validation {
#     error_message = "Invalid http path. Path must begin with a forward slash '/'"
#     condition     = try(alltrue(flatten([for function in values(var.config.function) : [for endpoint in values(function.trigger.https) : startswith(endpoint.path, "/")]])), true)
#   }

#   validation {
#     error_message = "Invalid http authorizer type. Valid values includes [JWT]"
#     condition     = try(alltrue(flatten([for function in values(var.config.function) : [for endpoint in values(function.trigger.https) : [for authorizer in values(endpoint.authorizer.type) : contains(["JWT"], authorizer.type)]]])), true)
#   }

#   ##### .trigger.rest #####

#   validation {
#     error_message = "Invalid rest method. Valid values includes [GET, POST, PUT, DELETE, PATCH]"
#     condition     = try(alltrue(flatten([for function in values(var.config.function) : [for endpoint in values(function.trigger.rest) : contains(["GET", "POST", "PUT", "DELETE", "PATCH"], endpoint.method)]])), true)
#   }

#   validation {
#     error_message = "Invalid rest path. Path must begin with a forward slash '/'"
#     condition     = try(alltrue(flatten([for function in values(var.config.function) : [for endpoint in values(function.trigger.rest) : startswith(endpoint.path, "/")]])), true)
#   }

#   validation {
#     error_message = "Invalid rest path. Path must begin with the same root name ex. '/api/'"
#     condition     = try(length(distinct(flatten([for function in values(var.config.function) : [for endpoint in values(function.trigger.rest) : split("/", endpoint.path)[1]]]))) <= 1, true)
#   }

#   validation {
#     error_message = "Invalid rest authorizer type. Valid values includes [token, request]"
#     condition     = try(alltrue(flatten([for function in values(var.config.function) : [for endpoint in values(function.trigger.rest) : [for authorizer in values(endpoint.authorizer.type) : contains(["token", "request"], authorizer.type)]]])), true)
#   }

#   ##### .trigger.queue #####

#   validation {
#     error_message = "Invalid key, trigger queue key must match one of the keys in config.queue"
#     condition     = try(alltrue(flatten([for func in values(var.config.function) : [for queue_name in keys(func.trigger.queue) : contains(keys(var.config.queue), queue_name)]])), true)
#   }

#   ##### .target.queue #####

#   validation {
#     error_message = "Invalid key, target queue key must match one of the keys in config.queue"
#     condition     = try(alltrue(flatten([for func in values(var.config.function) : [for queue_name in keys(func.target.queue) : contains(keys(var.config.queue), queue_name)]])), true)
#   }

#   ##### .environment_variable ######

# }
