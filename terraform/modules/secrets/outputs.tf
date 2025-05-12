output "database_arn" {
  description = "ARN of the database credentials secret"
  value       = data.aws_secretsmanager_secret.database.arn
}

output "sonar_token_arn" {
  description = "ARN of the SonarQube token secret"
  value       = data.aws_secretsmanager_secret.sonar_token.arn
}

output "source_token_arn" {
  description = "ARN of the source control token secret"
  value       = data.aws_secretsmanager_secret.source_token.arn
}

output "client_repository_arn" {
  description = "ARN of the client repository URL secret"
  value       = data.aws_secretsmanager_secret.client_repository.arn
}

output "admin_repository_arn" {
  description = "ARN of the admin repository URL secret"
  value       = data.aws_secretsmanager_secret.admin_repository.arn
}

output "container_image_arn" {
  description = "ARN of the container image URI secret"
  value       = data.aws_secretsmanager_secret.container_image.arn
}

# Add outputs for secret values if needed
output "database_secret" {
  description = "Database credentials secret value"
  value       = data.aws_secretsmanager_secret_version.database.secret_string
  sensitive   = true
}

output "sonar_token_secret" {
  description = "SonarQube token secret value"
  value       = data.aws_secretsmanager_secret_version.sonar_token.secret_string
  sensitive   = true
}

output "source_token_secret" {
  description = "Source control token secret value"
  value       = data.aws_secretsmanager_secret_version.source_token.secret_string
  sensitive   = true
}

output "client_repository_secret" {
  description = "Client repository URL secret value"
  value       = data.aws_secretsmanager_secret_version.client_repository.secret_string
  sensitive   = true
}

output "admin_repository_secret" {
  description = "Admin repository URL secret value"
  value       = data.aws_secretsmanager_secret_version.admin_repository.secret_string
  sensitive   = true
}

output "container_image_secret" {
  description = "Container image URI secret value"
  value       = data.aws_secretsmanager_secret_version.container_image.secret_string
  sensitive   = true
} 