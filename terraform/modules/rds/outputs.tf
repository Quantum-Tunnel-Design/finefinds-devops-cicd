output "db_instance_address" {
  description = "Address of the RDS instance"
  value       = aws_db_instance.main.address
}

output "db_instance_name" {
  description = "Name of the RDS instance"
  value       = aws_db_instance.main.identifier
}

output "db_instance_username" {
  description = "Master username of the RDS instance"
  value       = aws_db_instance.main.username
}

output "endpoint" {
  description = "Endpoint of the RDS instance"
  value       = aws_db_instance.main.endpoint
} 