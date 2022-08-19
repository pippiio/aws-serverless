variable "config" {
  type = object({
    cloudwatch_log_retention_in_days = optional(number)
  })
}

variable "queues" {
  description = "A map of sqs-queues to be created."
  type = map(object({
    visibility_timeout_seconds = optional(number)
    message_retention_seconds  = optional(number)
    delay_seconds              = optional(number)
    receive_wait_time_seconds  = optional(number)

    sns_subscriptions = optional(map(object({})))
  }))
  default = {}
}

variables "topics" {
  description = "A map of sns-topics to be created."
  type = map(object({
    fifo = optional(bool)
  }))
  default = {}
}

variable "functions" {
  description = "A map of lambda-functions to be created."
  type = map(object({
    description     = string
    src_path        = string
    # image_tag       = optional(string)
    timeout         = optional(number)
    memory_size     = optional(number)
    subnets         = optional(string)
    security_groups = optional(string)
    inline_policies = optional(map(string))

    environment_variables = optional(map(object({
      value = string
      type  = string
    })))

    permissions = optional(map(object({
      actions  = list(string)
      resource = string
    })))

    events = optional(object({
      sns = optional(map(object({})))
      sqs = optional(map(object({
        batch_size                         = optional(number)
        maximum_batching_window_in_seconds = optional(number)
      })))
      schedules = optional(map(object({
        cron = string
      })))
      https = optional(map(object({
        method = string
        path   = string
        public = bool
        # timeout_milliseconds 
        # throttle
      })))
    }))

    targets = optional(map(object({
      env_var_key = string
      type        = string
    })))
  }))
}
