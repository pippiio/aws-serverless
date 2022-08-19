variable "config" {
  type = object({

    topics = map(object({
      fifo = optional(bool)
    }))

    queues = map(object({
      visibility_timeout_seconds = optional(number)
      message_retention_seconds  = optional(number)
      delay_seconds              = optional(number)
      receive_wait_time_seconds  = optional(number)

      sns_subscriptions = optional(map(object({})))
    }))

    function = map(object({
      description = string
      #   src_path        = string

      runtime = optional(string)
      source = object({
        type = string # s3|ecr|github - pt kun s3
        path = string
      })

      #   image_tag       = optional(string)
      timeout     = optional(number)
      memory_size = optional(number)
      #   subnets         = optional(string)
      #   security_groups = optional(string)
      #   inline_policies = optional(map(string))

      environment_variables = optional(map(object({
        value = string
        type  = string # enten cleartext eller ssm param
      })))

      #   permissions = optional(map(object({
      #     actions  = list(string)
      #     resource = string
      #   })))

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


  })
}
