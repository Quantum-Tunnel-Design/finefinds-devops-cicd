# VPC Outputs
output "vpc_id" {
  description = "ID of the VPC"
  value       = module.networking.vpc_id
}

output "public_subnet_ids" {
  description = "List of public subnet IDs"
  value       = module.networking.public_subnet_ids
}

output "private_subnet_ids" {
  description = "List of private subnet IDs"
  value       = module.networking.private_subnet_ids
}

# Database Outputs
output "db_endpoint" {
  description = "Endpoint of the RDS instance"
  value       = module.database.db_endpoint
}

output "db_port" {
  description = "Port of the RDS instance"
  value       = module.database.db_port
}

output "db_name" {
  description = "Name of the RDS database"
  value       = module.database.db_name
}

output "db_username" {
  description = "Username of the RDS database"
  value       = module.database.db_username
  sensitive   = true
}

# Compute Outputs
output "cluster_name" {
  description = "Name of the ECS cluster"
  value       = module.backend.cluster_name
}

output "cluster_arn" {
  description = "ARN of the ECS cluster"
  value       = module.backend.cluster_arn
}

output "service_name" {
  description = "Name of the ECS service"
  value       = module.backend.service_name
}

output "service_arn" {
  description = "ARN of the ECS service"
  value       = module.backend.service_arn
}

output "task_definition_arn" {
  description = "ARN of the ECS task definition"
  value       = module.backend.task_definition_arn
}

output "alb_dns_name" {
  description = "DNS name of the load balancer"
  value       = module.backend.alb_dns_name
}

output "alb_arn" {
  description = "ARN of the load balancer"
  value       = module.backend.alb_arn
}

output "alb_zone_id" {
  description = "Zone ID of the load balancer"
  value       = module.backend.alb_zone_id
}

# Security Outputs
output "kms_key_id" {
  description = "ID of the KMS key"
  value       = module.security.kms_key_id
}

# Monitoring Outputs
output "log_group_name" {
  description = "Name of the CloudWatch log group"
  value       = module.backend.log_group_name
} 