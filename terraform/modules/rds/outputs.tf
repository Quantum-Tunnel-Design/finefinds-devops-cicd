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

output "db_instance_id" {
  description = "ID of the RDS instance"
  value       = aws_db_instance.main.id
}

output "db_instance_endpoint" {
  description = "Endpoint of the RDS instance"
  value       = aws_db_instance.main.endpoint
}

output "db_instance_identifier" {
  description = "Identifier of the RDS instance"
  value       = aws_db_instance.main.identifier
}

output "db_instance_port" {
  description = "Port of the RDS instance"
  value       = aws_db_instance.main.port
}

output "db_subnet_group_name" {
  description = "Name of the DB subnet group"
  value       = aws_db_subnet_group.main.name
}

output "security_group_id" {
  description = "ID of the RDS security group"
  value       = aws_security_group.rds.id
} 