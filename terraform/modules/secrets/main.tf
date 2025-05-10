# Generate random values for secrets
resource "random_password" "jwt_secret" {
  length           = 32
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

# JWT Secret
resource "aws_secretsmanager_secret" "jwt_secret" {
  name = "${var.project}-${var.environment}-jwt-secret"
  description = "JWT secret for ${var.environment} environment"

  tags = {
    Environment = var.environment
    Project     = var.project
    Terraform   = "true"
  }

  lifecycle {
    ignore_changes = [name]
  }
}

resource "aws_secretsmanager_secret_version" "jwt_secret" {
  secret_id     = aws_secretsmanager_secret.jwt_secret.id
  secret_string = random_password.jwt_secret.result
}

# Database URL Secret
data "aws_secretsmanager_secret" "database_url" {
  name = "${var.project}-${var.environment}-db-password"
}

data "aws_secretsmanager_secret_version" "database_url" {
  secret_id = data.aws_secretsmanager_secret.database_url.id
}

# MongoDB Password Secret
data "aws_secretsmanager_secret" "mongodb_password" {
  name = "${var.project}-${var.environment}-mongodb-password"
}

data "aws_secretsmanager_secret_version" "mongodb_password" {
  secret_id = data.aws_secretsmanager_secret.mongodb_password.id
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
output "database_url_arn" {
  description = "ARN of the database password in Secrets Manager"
  value       = data.aws_secretsmanager_secret.database_url.arn
  sensitive   = true
}

output "mongodb_uri_arn" {
  description = "ARN of the MongoDB password in Secrets Manager"
  value       = data.aws_secretsmanager_secret.mongodb_password.arn
  sensitive   = true
}

output "jwt_secret_arn" {
  description = "ARN of the JWT secret in Secrets Manager"
  value       = aws_secretsmanager_secret.jwt_secret.arn
  sensitive   = true
} 