output "database_arn" {
  description = "ARN of the database credentials secret (stores {username, password, ...})"
  value       = aws_secretsmanager_secret.database.arn
}

output "sonar_token_arn" {
  description = "ARN of the SonarQube token secret (stores {token})"
  value       = aws_secretsmanager_secret.sonar_token.arn
}

output "source_token_arn" {
  description = "ARN of the source control token secret (stores {token})"
  value       = aws_secretsmanager_secret.source_token.arn
}

output "client_repository_arn" {
  description = "ARN of the client repository URL secret (stores {url})"
  value       = aws_secretsmanager_secret.client_repository.arn
}

output "admin_repository_arn" {
  description = "ARN of the admin repository URL secret (stores {url})"
  value       = aws_secretsmanager_secret.admin_repository.arn
}

output "container_image_arn" {
  description = "ARN of the container image URI secret (stores {image})"
  value       = aws_secretsmanager_secret.container_image.arn
} 