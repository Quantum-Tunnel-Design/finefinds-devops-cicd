output "db_instance_id" {
  description = "ID of the RDS instance"
  value       = local.db_instance_id
}

output "db_instance_endpoint" {
  description = "Endpoint of the RDS instance"
  value       = local.db_instance_endpoint
}

output "db_instance_port" {
  description = "Port of the RDS instance"
  value       = local.db_instance_port
}

output "db_instance_identifier" {
  description = "Identifier of the RDS instance"
  value       = local.db_instance_id
}

output "db_instance_address" {
  description = "Address of the RDS instance"
  value       = local.db_instance_endpoint
}

output "db_subnet_group_name" {
  description = "Name of the DB subnet group"
  value       = var.use_existing_subnet_group ? data.aws_db_subnet_group.existing[0].name : aws_db_subnet_group.main.name
}

output "security_group_id" {
  description = "ID of the RDS security group"
  value       = aws_security_group.main.id
}
