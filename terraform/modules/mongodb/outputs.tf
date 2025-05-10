output "cluster_id" {
  description = "The cluster identifier"
  value       = aws_docdb_cluster.main.id
}

output "cluster_endpoint" {
  description = "The cluster endpoint"
  value       = aws_docdb_cluster.main.endpoint
}

output "cluster_port" {
  description = "The cluster port"
  value       = aws_docdb_cluster.main.port
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

output "security_group_id" {
  description = "The security group ID"
  value       = aws_security_group.mongodb.id
}

output "subnet_group_name" {
  description = "The subnet group name"
  value       = aws_docdb_subnet_group.main.name
} 