output "name_prefix" {
  description = "Common name prefix for resources"
  value       = local.name_prefix
}

output "base_tags" {
  description = "Base tags that should be present on all resources"
  value       = local.base_tags
}

output "common_tags" {
  description = "Common tags that can be extended by modules"
  value       = local.common_tags
}

output "current_env_config" {
  description = "Current environment configuration"
  value       = local.current_env_config
}

output "current_vpc_config" {
  description = "Current VPC configuration"
  value       = local.current_vpc_config
}

output "environment" {
  description = "Environment name"
  value       = var.environment
}

output "tags" {
  description = "Common tags applied to all resources"
  value       = local.common_tags
}

output "has_vpc" {
  description = "Whether VPC is configured"
  value       = local.has_vpc
}

output "has_private_subnets" {
  description = "Whether private subnets are configured"
  value       = local.has_private_subnets
}

output "has_public_subnets" {
  description = "Whether public subnets are configured"
  value       = local.has_public_subnets
} 