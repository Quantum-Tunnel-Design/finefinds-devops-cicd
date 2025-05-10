output "db_instance_address" {
  description = "Address of the RDS instance"
  value       = var.use_existing_instance ? data.aws_db_instance.existing[0].address : aws_db_instance.main[0].address
}

output "db_instance_name" {
  description = "Name of the RDS instance"
  value       = var.use_existing_instance ? data.aws_db_instance.existing[0].db_name : aws_db_instance.main[0].identifier
}

output "db_instance_username" {
  description = "Username of the RDS instance"
  value       = var.use_existing_instance ? data.aws_db_instance.existing[0].master_username : aws_db_instance.main[0].username
}

output "endpoint" {
  description = "Endpoint of the RDS instance"
  value       = var.use_existing_instance ? data.aws_db_instance.existing[0].endpoint : aws_db_instance.main[0].endpoint
} 