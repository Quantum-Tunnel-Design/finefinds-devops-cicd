output "log_group_name" {
  description = "Name of the CloudWatch log group"
  value       = aws_cloudwatch_log_group.ecs.name
}

output "dashboard_name" {
  description = "Name of the CloudWatch dashboard"
  value       = aws_cloudwatch_dashboard.main.dashboard_name
}

output "sns_topic_arn" {
  description = "ARN of the SNS topic for alerts"
  value       = aws_sns_topic.alerts.arn
}

output "alarm_names" {
  description = "Names of all configured alarms"
  value = {
    cpu_utilization    = aws_cloudwatch_metric_alarm.cpu_utilization.alarm_name
    memory_utilization = aws_cloudwatch_metric_alarm.memory_utilization.alarm_name
    rds_cpu           = aws_cloudwatch_metric_alarm.rds_cpu.alarm_name
    rds_memory        = aws_cloudwatch_metric_alarm.rds_memory.alarm_name
    error_rate        = aws_cloudwatch_metric_alarm.error_rate.alarm_name
    latency           = aws_cloudwatch_metric_alarm.latency.alarm_name
  }
} 