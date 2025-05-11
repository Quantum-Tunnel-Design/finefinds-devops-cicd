output "log_group_name" {
  description = "Name of the CloudWatch log group"
  value       = aws_cloudwatch_log_group.app.name
}

output "dashboard_arn" {
  description = "ARN of the CloudWatch dashboard"
  value       = aws_cloudwatch_dashboard.main.dashboard_arn
}

output "alerts_topic_arn" {
  description = "ARN of the SNS topic for alerts"
  value       = aws_sns_topic.alerts.arn
}

output "alarm_names" {
  description = "Names of the CloudWatch alarms"
  value = {
    ecs_cpu    = aws_cloudwatch_metric_alarm.ecs_cpu.alarm_name
    ecs_memory = aws_cloudwatch_metric_alarm.ecs_memory.alarm_name
    rds_cpu    = aws_cloudwatch_metric_alarm.rds_cpu.alarm_name
  }
} 