output "vpc_id" {
  description = "ID of the VPC"
  value       = module.networking.vpc_id
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = module.networking.private_subnet_ids
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = module.networking.public_subnet_ids
}

output "database_subnet_ids" {
  description = "IDs of the database subnets"
  value       = module.networking.database_subnet_ids
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
  value       = module.rds.db_instance_endpoint
}

output "db_secret_arn" {
  description = "ARN of the RDS database secret"
  value       = module.secrets.database_arn
}

output "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  value       = module.compute.cluster_name
}

output "ecs_service_name" {
  description = "Name of the ECS service"
  value       = module.compute.service_name
}

output "alb_dns_name" {
  description = "DNS name of the load balancer"
  value       = module.alb.alb_dns_name
}

output "cognito_user_pool_id" {
  description = "ID of the Client Cognito User Pool"
  value       = module.cognito.client_user_pool_id
}

output "cognito_user_pool_client_id" {
  description = "ID of the Client App Cognito User Pool Client"
  value       = module.cognito.client_app_client_id
}

output "kms_key_id" {
  description = "ID of the KMS key"
  value       = module.security.kms_key_id
}

output "certificate_arn" {
  description = "ARN of the ACM certificate"
  value       = module.security.certificate_arn
} 