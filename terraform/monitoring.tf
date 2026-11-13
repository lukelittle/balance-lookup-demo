# ---------------------------------------------------------------------------
# The "security cameras": alarm + dashboard.
# ---------------------------------------------------------------------------

resource "aws_sns_topic" "alerts" {
  name = "${local.name}-alerts"
}

resource "aws_sns_topic_subscription" "email" {
  count     = var.alarm_email == "" ? 0 : 1
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.alarm_email
}

# Fires when the function reports errors in a 1-minute window.
resource "aws_cloudwatch_metric_alarm" "errors" {
  alarm_name          = "${local.name}-errors"
  alarm_description   = "Balance lookup is returning errors. Runbook: see README 'When the alarm fires'."
  namespace           = "AWS/Lambda"
  metric_name         = "Errors"
  dimensions          = { FunctionName = aws_lambda_function.balance.function_name }
  statistic           = "Sum"
  period              = 60
  evaluation_periods  = 1
  threshold           = 1
  comparison_operator = "GreaterThanOrEqualToThreshold"
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  ok_actions          = [aws_sns_topic.alerts.arn]
}

# Fires when p99 latency eats most of the timeout budget.
resource "aws_cloudwatch_metric_alarm" "latency" {
  alarm_name          = "${local.name}-p99-latency"
  alarm_description   = "Balance lookup p99 latency above 1s."
  namespace           = "AWS/Lambda"
  metric_name         = "Duration"
  dimensions          = { FunctionName = aws_lambda_function.balance.function_name }
  extended_statistic  = "p99"
  period              = 60
  evaluation_periods  = 2
  threshold           = 1000
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  ok_actions          = [aws_sns_topic.alerts.arn]
}

# TODO(week 1 assignment): add aws_cloudwatch_metric_alarm.throttles on the
# Lambda "Throttles" metric, wired to the SNS topic like the alarms above.
# Add it to the dashboard's Alarms widget and to the alarm_names output.
# In your proposal: when would NNB see throttling, and is 1 throttle in a
# minute the right threshold? (Try: aws lambda put-function-concurrency
#   --function-name <name> --reserved-concurrent-executions 0)

resource "aws_cloudwatch_dashboard" "balance" {
  dashboard_name = local.name
  dashboard_body = jsonencode({
    widgets = [
      {
        type = "metric", x = 0, y = 0, width = 12, height = 6
        properties = {
          title  = "Requests vs errors (per minute)"
          region = var.region
          stat   = "Sum"
          period = 60
          view   = "timeSeries"
          metrics = [
            ["AWS/Lambda", "Invocations", "FunctionName", aws_lambda_function.balance.function_name],
            [".", "Errors", ".", ".", { color = "#d62728" }],
            [".", "Throttles", ".", ".", { color = "#ff7f0e" }],
          ]
        }
      },
      {
        type = "metric", x = 12, y = 0, width = 12, height = 6
        properties = {
          title  = "Latency (ms)"
          region = var.region
          period = 60
          view   = "timeSeries"
          metrics = [
            ["AWS/Lambda", "Duration", "FunctionName", aws_lambda_function.balance.function_name, { stat = "p50" }],
            ["...", { stat = "p99" }],
          ]
        }
      },
      {
        type = "alarm", x = 0, y = 6, width = 24, height = 3
        properties = {
          title  = "Alarms"
          alarms = [aws_cloudwatch_metric_alarm.errors.arn, aws_cloudwatch_metric_alarm.latency.arn]
        }
      },
      {
        type = "log", x = 0, y = 9, width = 24, height = 6
        properties = {
          title  = "Recent errors"
          region = var.region
          query  = "SOURCE '${aws_cloudwatch_log_group.lambda.name}' | fields @timestamp, level, msg, account_id | filter level = 'ERROR' | sort @timestamp desc | limit 20"
          view   = "table"
        }
      },
    ]
  })
}
