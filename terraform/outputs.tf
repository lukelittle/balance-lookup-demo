output "api_url" {
  description = "Public URL of the balance-lookup API. Try: curl \"$(terraform output -raw api_url)?account_id=1001\""
  value       = aws_lambda_function_url.balance.function_url
}

output "function_name" {
  value = aws_lambda_function.balance.function_name
}

output "dashboard_url" {
  description = "Open this in the browser where you are signed in to the AWS console."
  value       = "https://${var.region}.console.aws.amazon.com/cloudwatch/home?region=${var.region}#dashboards/dashboard/${aws_cloudwatch_dashboard.balance.dashboard_name}"
}

output "alarm_names" {
  value = [aws_cloudwatch_metric_alarm.errors.alarm_name, aws_cloudwatch_metric_alarm.latency.alarm_name]
}

output "region" {
  description = "Region the stack is deployed in. The scripts pass it to the aws CLI, so they work even with no default region configured."
  value       = var.region
}

output "failure_rate" {
  description = "Injected failure rate the function is running with (0 = healthy). Check it after scripts/chaos.sh."
  value       = var.failure_rate
}
