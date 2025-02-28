
resource "aws_cloudwatch_event_rule" "this" {
  for_each = var.cron

  name                = "${each.key}-schedule"
  description         = "EventBridge Schedule for ${each.key} Lambda Function"
  schedule_expression = each.value.schedule_exp
}

resource "aws_cloudwatch_event_target" "this" {
  for_each = var.cron

  rule      = aws_cloudwatch_event_rule.this[each.key].name
  target_id = "monitoring-trigger-${each.key}"
  arn       = aws_lambda_function.function[each.key].arn
}

resource "aws_lambda_permission" "this" {
  for_each = var.cron

  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.function[each.key].function_name
  principal     = "events.amazonaws.com"
}
