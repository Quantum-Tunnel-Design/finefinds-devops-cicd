output "vpc_id" {
  description = "ID of the VPC"
  value       = module.network.vpc_id
}

output "private_subnet_ids" {
  description = "List of private subnet IDs"
  value       = module.network.private_subnet_ids
}

output "public_subnet_ids" {
  description = "List of public subnet IDs"
  value       = module.network.public_subnet_ids
}

output "database_subnet_ids" {
  description = "List of database subnet IDs"
  value       = module.network.database_subnet_ids
}

output "bucket_ids" {
  description = "Map of bucket names to their IDs"
  value       = module.storage.bucket_ids
}

output "bucket_arns" {
  description = "Map of bucket names to their ARNs"
  value       = module.storage.bucket_arns
}

output "db_endpoint" {
  description = "RDS instance endpoint"
  value       = module.database.db_endpoint
}

output "db_secret_arn" {
  description = "ARN of the RDS database secret"
  value       = module.database.db_secret_arn
}

output "mongodb_secret_arn" {
  description = "ARN of the MongoDB secret"
  value       = module.database.mongodb_secret_arn
}

output "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  value       = module.compute.ecs_cluster_name
}

output "ecs_service_name" {
  description = "Name of the ECS service"
  value       = module.compute.ecs_service_name
}

output "alb_dns_name" {
  description = "DNS name of the load balancer"
  value       = module.compute.alb_dns_name
}


output "cognito_user_pool_id" {
  description = "ID of the Cognito user pool"
  value       = module.security.cognito_user_pool_id
}

output "cognito_user_pool_client_id" {
  description = "ID of the Cognito user pool client"
  value       = module.security.cognito_user_pool_client_id
}

output "kms_key_id" {
  description = "ID of the KMS key"
  value       = module.security.kms_key_id
}

output "certificate_arn" {
  description = "ARN of the ACM certificate"
  value       = module.security.certificate_arn
} 