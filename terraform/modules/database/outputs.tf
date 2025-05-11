output "db_instance_id" {
  description = "ID of the RDS instance"
  value       = aws_db_instance.main.id
}

output "db_endpoint" {
  description = "Endpoint of the RDS instance"
  value       = aws_db_instance.main.endpoint
}

output "db_name" {
  description = "Name of the database"
  value       = aws_db_instance.main.db_name
}

output "db_port" {
  description = "Port of the RDS instance"
  value       = aws_db_instance.main.port
}

output "db_username" {
  description = "Username of the RDS database"
  value       = aws_db_instance.main.username
  sensitive   = true
}

output "db_instance_address" {
  description = "Address of the RDS instance"
  value       = aws_db_instance.main.address
}

output "db_security_group_id" {
  description = "Security group ID of the RDS instance"
  value       = aws_security_group.db.id
}

output "db_subnet_group_id" {
  description = "Subnet group ID of the RDS instance"
  value       = aws_db_subnet_group.main.id
}

output "db_parameter_group_id" {
  description = "Parameter group ID of the RDS instance"
  value       = aws_db_parameter_group.main.id
}

output "db_option_group_id" {
  description = "Option group ID of the RDS instance"
  value       = aws_db_option_group.main.id
}

output "rds_secret_arn" {
  description = "ARN of the RDS credentials secret"
  value       = aws_secretsmanager_secret.db.arn
}

output "alarm_topic_arn" {
  description = "ARN of the SNS topic for RDS alarms"
  value       = aws_sns_topic.alerts.arn
} 