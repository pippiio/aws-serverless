variable "config" {
  type = object({

    kms_key_id = optional(string)

    topic = optional(map(object({
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
    })))

    queue = optional(map(object({
      public                     = bool
      visibility_timeout_seconds = optional(number)
      message_retention_seconds  = optional(number)
      delay_seconds              = optional(number)
      receive_wait_time_seconds  = optional(number)

      sns_subscriptions = optional(set(string))
    })))

    storage = optional(map(object({})))

    database = optional(map(object({})))

    function = optional(map(object({
      description        = optional(string)
      iam_role           = optional(string)
      timeout            = optional(number)
      memory_size        = optional(number)
      subnet_ids         = optional(set(string))
      security_group_ids = optional(string)
      iam_policies       = optional(set(string))
      inline_policies    = optional(map(string))

      source = object({
        type    = string
        runtime = optional(string)
        path    = string
      })

      environment_variable = optional(map(object({
        type  = string # text|secret
        value = string
      })))

      #   trigger = optional(map(object({
      #     topic = optional(string)
      #     queue
      #     schedule
      #     https
      #     file
      #     log
      #     email
      #   loadbalancer
      #   })))

      target = optional(map(object({
        #   topic
        #   queue
        #   function
      })))
    })))

  })

  ##### Topic #####

  validation {
    error_message = "Topic names can include alphanumeric characters, hyphens (-) and underscores."
    condition     = try(alltrue([for name in keys(var.config.topic) : length(regexall("^[a-zA-Z0-9_-]+$", name)) > 0]), true)
  }

  validation {
    error_message = "Topic policy and publisher are mutually exclusive."
    condition     = try(alltrue([for topic in values(var.config.topic) : !(topic.policy != null && topic.publisher != null)]), true)
  }

  ##### .subscriber #####

  validation {
    error_message = "Invalid subscriber protocol. Valid values includes [lambda, email, email-json, sms, http, https]."
    condition     = try(alltrue(flatten([for topic in values(var.config.topic) : [for subscriber in values(topic.subscriber) : contains(["lambda", "email", "email-json", "sms", "http", "https", "sqs"], subscriber.protocol)] if topic.subscriber != null])), true)
  }

  validation {
    error_message = "Only sqs subscriber protocol can be used with FIFO topics."
    condition     = try(alltrue(flatten([for topic in values(var.config.topic) : [for subscriber in values(topic.subscriber) : subscriber.protocol == "sqs"] if coalesce(topic.fifo, false)])), true)
  }

  ##### .publisher #####

  validation {
    error_message = "Invalid publisher type. Valid values includes [service, account, organization, arn]."
    condition     = try(alltrue(flatten([for topic in values(var.config.topic) : [for publisher in values(topic.publisher) : contains(["service", "account", "organization", "arn"], publisher.type)] if topic.publisher != null])), true)
  }
}
