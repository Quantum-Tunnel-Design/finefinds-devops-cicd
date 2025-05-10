# Generate random passwords
resource "random_password" "jwt_secret" {
  length  = 32
  special = true
}

resource "random_password" "database_password" {
  length  = 32
  special = true
}

resource "random_password" "mongodb_password" {
  length  = 32
  special = true
}

# Create JWT secret
resource "aws_secretsmanager_secret" "jwt_secret" {
  name        = "${var.project}-${var.environment}-jwt-secret-${formatdate("YYYYMMDDHHmmss", timestamp())}"
  description = "JWT secret for ${var.project} ${var.environment} environment"
}

resource "aws_secretsmanager_secret_version" "jwt_secret" {
  secret_id     = aws_secretsmanager_secret.jwt_secret.id
  secret_string = random_password.jwt_secret.result
}

# Create database URL secret
resource "aws_secretsmanager_secret" "database_url" {
  name        = "${var.project}-${var.environment}-db-password-${formatdate("YYYYMMDDHHmmss", timestamp())}"
  description = "Database password for ${var.project} ${var.environment} environment"
}

resource "aws_secretsmanager_secret_version" "database_url" {
  secret_id     = aws_secretsmanager_secret.database_url.id
  secret_string = random_password.database_password.result
}

# Create MongoDB password secret
resource "aws_secretsmanager_secret" "mongodb_password" {
  name        = "${var.project}-${var.environment}-mongodb-password-${formatdate("YYYYMMDDHHmmss", timestamp())}"
  description = "MongoDB password for ${var.project} ${var.environment} environment"
}

resource "aws_secretsmanager_secret_version" "mongodb_password" {
  secret_id     = aws_secretsmanager_secret.mongodb_password.id
  secret_string = random_password.mongodb_password.result
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
output "jwt_secret_arn" {
  value       = aws_secretsmanager_secret.jwt_secret.arn
  description = "ARN of the JWT secret"
}

output "database_url_arn" {
  value       = aws_secretsmanager_secret.database_url.arn
  description = "ARN of the database URL secret"
}

output "mongodb_uri_arn" {
  value       = aws_secretsmanager_secret.mongodb_password.arn
  description = "ARN of the MongoDB password secret"
}

output "jwt_secret" {
  value       = random_password.jwt_secret.result
  description = "Generated JWT secret"
  sensitive   = true
}

output "database_password" {
  value       = random_password.database_password.result
  description = "Generated database password"
  sensitive   = true
}

output "mongodb_password" {
  value       = random_password.mongodb_password.result
  description = "Generated MongoDB password"
  sensitive   = true
} 