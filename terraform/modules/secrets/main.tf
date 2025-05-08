# Database URL Secret
resource "aws_secretsmanager_secret" "database_url" {
  name = "${var.project}-${var.environment}-database-url"
  description = "Database connection URL for ${var.environment} environment"

  tags = {
    Environment = var.environment
    Project     = var.project
    Terraform   = "true"
  }
}

resource "aws_secretsmanager_secret_version" "database_url" {
  secret_id     = aws_secretsmanager_secret.database_url.id
  secret_string = var.database_url
}

# MongoDB URI Secret
resource "aws_secretsmanager_secret" "mongodb_uri" {
  name = "${var.project}-${var.environment}-mongodb-uri"
  description = "MongoDB connection URI for ${var.environment} environment"

  tags = {
    Environment = var.environment
    Project     = var.project
    Terraform   = "true"
  }
}

resource "aws_secretsmanager_secret_version" "mongodb_uri" {
  secret_id     = aws_secretsmanager_secret.mongodb_uri.id
  secret_string = var.mongodb_uri
}

# JWT Secret
resource "aws_secretsmanager_secret" "jwt_secret" {
  name = "${var.project}-${var.environment}-jwt-secret"
  description = "JWT signing secret for ${var.environment} environment"

  tags = {
    Environment = var.environment
    Project     = var.project
    Terraform   = "true"
  }
}

resource "aws_secretsmanager_secret_version" "jwt_secret" {
  secret_id     = aws_secretsmanager_secret.jwt_secret.id
  secret_string = var.jwt_secret
}

# Cognito Client Secret
resource "aws_secretsmanager_secret" "cognito_client_secret" {
  name = "${var.project}-${var.environment}-cognito-client-secret"
  description = "Cognito client secret for ${var.environment} environment"

  tags = {
    Environment = var.environment
    Project     = var.project
    Terraform   = "true"
  }
}

resource "aws_secretsmanager_secret_version" "cognito_client_secret" {
  secret_id     = aws_secretsmanager_secret.cognito_client_secret.id
  secret_string = var.cognito_client_secret
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

variable "database_url" {
  description = "Database connection URL"
  type        = string
  sensitive   = true
}

variable "mongodb_uri" {
  description = "MongoDB connection URI"
  type        = string
  sensitive   = true
}

variable "jwt_secret" {
  description = "JWT signing secret"
  type        = string
  sensitive   = true
}

variable "cognito_client_secret" {
  description = "Cognito client secret"
  type        = string
  sensitive   = true
}

# Outputs
output "database_url_arn" {
  description = "ARN of the database URL secret"
  value       = aws_secretsmanager_secret.database_url.arn
}

output "mongodb_uri_arn" {
  description = "ARN of the MongoDB URI secret"
  value       = aws_secretsmanager_secret.mongodb_uri.arn
}

output "jwt_secret_arn" {
  description = "ARN of the JWT secret"
  value       = aws_secretsmanager_secret.jwt_secret.arn
}

output "cognito_client_secret_arn" {
  description = "ARN of the Cognito client secret"
  value       = aws_secretsmanager_secret.cognito_client_secret.arn
} 