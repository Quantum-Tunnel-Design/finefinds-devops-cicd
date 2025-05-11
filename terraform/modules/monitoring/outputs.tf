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

output "cloudwatch_log_groups" {
  description = "Map of CloudWatch log group names"
  value = {
    alb       = var.enable_cloudwatch ? aws_cloudwatch_log_group.alb.name : null
    ecs       = var.enable_cloudwatch ? aws_cloudwatch_log_group.ecs.name : null
    rds       = var.enable_cloudwatch ? aws_cloudwatch_log_group.rds.name : null
    cloudtrail = var.enable_cloudtrail ? aws_cloudwatch_log_group.cloudtrail.name : null
  }
}

output "cloudwatch_alarms" {
  description = "Map of CloudWatch alarm names"
  value = {
    alb_5xx = var.enable_cloudwatch ? aws_cloudwatch_metric_alarm.alb_5xx.alarm_name : null
    ecs_cpu = var.enable_cloudwatch ? aws_cloudwatch_metric_alarm.ecs_cpu.alarm_name : null
    rds_cpu = var.enable_cloudwatch ? aws_cloudwatch_metric_alarm.rds_cpu.alarm_name : null
  }
}

output "sns_topic_arn" {
  description = "ARN of the SNS topic for alerts"
  value       = var.enable_cloudwatch ? aws_sns_topic.alerts.arn : null
}

output "xray_group_arn" {
  description = "ARN of the X-Ray group"
  value       = var.enable_xray ? aws_xray_group.main.arn : null
}

output "cloudtrail_arn" {
  description = "ARN of the CloudTrail trail"
  value       = var.enable_cloudtrail ? aws_cloudtrail.main.arn : null
}

output "cloudtrail_s3_bucket" {
  description = "ID of the S3 bucket used for CloudTrail"
  value       = var.enable_cloudtrail ? aws_s3_bucket.cloudtrail.id : null
}

output "cloudtrail_role_arn" {
  description = "ARN of the IAM role used by CloudTrail"
  value       = var.enable_cloudtrail ? aws_iam_role.cloudtrail.arn : null
} 