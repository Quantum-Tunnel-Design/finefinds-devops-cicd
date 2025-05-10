# Database URL Secret
data "aws_secretsmanager_secret" "database_url" {
  name = "finefinds/${var.environment}/db-password"
}

data "aws_secretsmanager_secret_version" "database_url" {
  secret_id = data.aws_secretsmanager_secret.database_url.id
}

# SonarQube Database Password Secret
data "aws_secretsmanager_secret" "sonarqube_db_password" {
  name = "finefinds/${var.environment}/sonarqube-db-password"
}

data "aws_secretsmanager_secret_version" "sonarqube_db_password" {
  secret_id = data.aws_secretsmanager_secret.sonarqube_db_password.id
}

# JWT Secret
data "aws_secretsmanager_secret" "jwt_secret" {
  name = "finefinds/${var.environment}/jwt-secret"
}

data "aws_secretsmanager_secret_version" "jwt_secret" {
  secret_id = data.aws_secretsmanager_secret.jwt_secret.id
}

# Variables
variable "project" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

# Outputs
output "database_password" {
  description = "Database password"
  value       = data.aws_secretsmanager_secret_version.database_url.secret_string
  sensitive   = true
}

output "sonarqube_db_password" {
  description = "SonarQube database password"
  value       = data.aws_secretsmanager_secret_version.sonarqube_db_password.secret_string
  sensitive   = true
}

output "jwt_secret" {
  description = "JWT signing secret"
  value       = data.aws_secretsmanager_secret_version.jwt_secret.secret_string
  sensitive   = true
} 