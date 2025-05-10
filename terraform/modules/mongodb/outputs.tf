output "endpoint" {
  description = "Endpoint of the MongoDB instance"
  value       = local.cluster_endpoint
}

output "port" {
  description = "Port of the MongoDB instance"
  value       = aws_docdb_cluster.main.port
}

output "security_group_id" {
  description = "ID of the MongoDB security group"
  value       = aws_security_group.mongodb.id
}

output "cluster_identifier" {
  description = "Identifier of the MongoDB cluster"
  value       = aws_docdb_cluster.main.cluster_identifier
}

output "subnet_group_name" {
  description = "Name of the DB subnet group"
  value       = aws_docdb_subnet_group.main.name
}

output "cluster_reader_endpoint" {
  description = "The cluster reader endpoint"
  value       = aws_docdb_cluster.main.reader_endpoint
}

output "cluster_master_username" {
  description = "The master username for the cluster"
  value       = aws_docdb_cluster.main.master_username
}

output "cluster_master_password_arn" {
  description = "The ARN of the master password secret"
  value       = var.mongodb_password_arn
} 