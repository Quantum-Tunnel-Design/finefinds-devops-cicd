output "ecs_task_execution_role_arn" {
  description = "ARN of the ECS task execution role"
  value       = aws_iam_role.ecs_task_execution.arn
}

output "ecs_task_role_arn" {
  description = "ARN of the ECS task role"
  value       = aws_iam_role.ecs_task.arn
}

output "kms_key_id" {
  description = "ID of the KMS key"
  value       = var.enable_encryption ? aws_kms_key.main[0].key_id : null
}

output "kms_key_arn" {
  description = "ARN of the KMS key"
  value       = var.enable_encryption ? aws_kms_key.main[0].arn : null
}

output "backup_vault_arn" {
  description = "ARN of the backup vault"
  value       = var.enable_backup ? aws_backup_vault.main[0].arn : null
}

output "backup_plan_arn" {
  description = "ARN of the backup plan"
  value       = var.enable_backup ? aws_backup_plan.main[0].arn : null
}

output "backup_role_arn" {
  description = "ARN of the backup IAM role"
  value       = var.enable_backup ? aws_iam_role.backup[0].arn : null
}

output "cloudwatch_role_arn" {
  description = "ARN of the CloudWatch IAM role"
  value       = var.enable_monitoring ? aws_iam_role.cloudwatch[0].arn : null
}

output "cloudwatch_dashboard_url" {
  description = "URL of the CloudWatch dashboard"
  value       = var.enable_monitoring ? "https://${data.aws_region.current.name}.console.aws.amazon.com/cloudwatch/home?region=${data.aws_region.current.name}#dashboards:name=${var.name_prefix}-${var.environment}-dashboard" : null
}

output "certificate_arn" {
  description = "ARN of the ACM certificate"
  value       = var.certificate_arn
}

output "db_security_group_id" {
  description = "ID of the database security group"
  value       = aws_security_group.db.id
}

output "vpc_id" {
  description = "ID of the VPC"
  value       = var.vpc_id
}

output "security_group_id" {
  description = "ID of the security group"
  value       = aws_security_group.db.id
}

output "cloudwatch_dashboard_arn" {
  description = "ARN of the CloudWatch dashboard"
  value       = var.enable_monitoring ? aws_cloudwatch_dashboard.main[0].dashboard_arn : null
} 