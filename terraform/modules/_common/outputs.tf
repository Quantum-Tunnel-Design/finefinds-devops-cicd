output "name_prefix" {
  description = "Prefix used for resource names"
  value       = var.name_prefix
}

output "environment" {
  description = "Environment name"
  value       = var.environment
}

output "tags" {
  description = "Common tags applied to all resources"
  value       = local.common_tags
} 