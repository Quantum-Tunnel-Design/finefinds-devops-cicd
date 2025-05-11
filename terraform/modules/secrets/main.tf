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

resource "random_password" "sonarqube_password" {
  length  = 32
  special = true
}

# JWT Secret
resource "aws_secretsmanager_secret" "jwt_secret" {
  count = var.use_existing_secrets ? 0 : 1
  name  = "${var.project}-${var.environment}-jwt-secret-${var.secret_suffix}"

  tags = {
    Environment = var.environment
    Project     = var.project
    Terraform   = "true"
  }

  lifecycle {
    ignore_changes = [name]
  }
}

# Database Password Secret
resource "aws_secretsmanager_secret" "database_password" {
  count = var.use_existing_secrets ? 0 : 1
  name  = "${var.project}-${var.environment}-db-password-${var.secret_suffix}"

  tags = {
    Environment = var.environment
    Project     = var.project
    Terraform   = "true"
  }
}

resource "aws_secretsmanager_secret_version" "database_password" {
  count          = var.use_existing_secrets ? 0 : 1
  secret_id      = aws_secretsmanager_secret.database_password[0].id
  secret_string  = jsonencode({
    password = var.db_password
  })
}

# MongoDB Password Secret
resource "aws_secretsmanager_secret" "mongodb_password" {
  name        = "${var.project}/${var.environment}/mongodb-password"
  description = "MongoDB password for ${var.environment} environment"
  tags        = var.tags
}

resource "aws_secretsmanager_secret_version" "mongodb_password" {
  secret_id     = aws_secretsmanager_secret.mongodb_password.id
  secret_string = jsonencode({
    password = var.mongodb_password
  })
}

# SonarQube Password Secret
resource "aws_secretsmanager_secret" "sonarqube_password" {
  count = var.use_existing_secrets ? 0 : 1
  name  = "${var.project}-${var.environment}-sonarqube-password-${var.secret_suffix}"

  tags = {
    Environment = var.environment
    Project     = var.project
    Terraform   = "true"
  }
}

resource "aws_secretsmanager_secret_version" "sonarqube_password" {
  count          = var.use_existing_secrets ? 0 : 1
  secret_id      = aws_secretsmanager_secret.sonarqube_password[0].id
  secret_string  = jsonencode({
    password = var.sonarqube_password
  })
}

# Use existing or new secrets
locals {
  jwt_secret_arn      = var.use_existing_secrets ? "arn:aws:secretsmanager:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:secret:${var.project}-${var.environment}-jwt-secret-${var.secret_suffix}" : aws_secretsmanager_secret.jwt_secret[0].arn
  db_password_arn     = var.use_existing_secrets ? "arn:aws:secretsmanager:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:secret:${var.project}-${var.environment}-db-password-${var.secret_suffix}" : aws_secretsmanager_secret.database_password[0].arn
  mongodb_password_arn = aws_secretsmanager_secret.mongodb_password.arn
  sonarqube_password_arn = var.use_existing_secrets ? "arn:aws:secretsmanager:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:secret:${var.project}-${var.environment}-sonarqube-password-${var.secret_suffix}" : aws_secretsmanager_secret.sonarqube_password[0].arn
}

# Get current AWS account ID and region
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# Variables
variable "project" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "use_existing_secrets" {
  description = "Whether to use existing secrets"
  type        = bool
  default     = true
}

variable "secret_suffix" {
  description = "Secret suffix"
  type        = string
}

# Outputs
output "jwt_secret_arn" {
  value       = local.jwt_secret_arn
  description = "ARN of the JWT secret"
}

output "database_password_arn" {
  value       = local.db_password_arn
  description = "ARN of the database password secret"
}

# Output the ARN for use in other modules
output "mongodb_password_arn" {
  description = "ARN of the MongoDB password secret"
  value       = data.aws_secretsmanager_secret.mongodb_password.arn
  sensitive   = true
} 

output "sonarqube_password_arn" {
  value       = local.sonarqube_password_arn
  description = "ARN of the SonarQube password secret"
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

output "sonarqube_password" {
  value       = random_password.sonarqube_password.result
  description = "Generated SonarQube password"
  sensitive   = true
}

# Secrets Manager Secret for Database Credentials
resource "aws_secretsmanager_secret" "database" {
  name = "${var.project}-${var.environment}-database-credentials"
  description = "Database credentials for ${var.project} ${var.environment} environment"

  tags = {
    Environment = var.environment
    Project     = var.project
    Terraform   = "true"
  }
}

resource "aws_secretsmanager_secret_version" "database" {
  secret_id = aws_secretsmanager_secret.database.id
  secret_string = jsonencode({
    username = var.db_username
    password = var.db_password
    host     = var.db_host
    port     = var.db_port
    database = var.db_name
  })
}

# Secrets Manager Secret for MongoDB Credentials
resource "aws_secretsmanager_secret" "mongodb" {
  name = "${var.project}-${var.environment}-mongodb-credentials"
  description = "MongoDB credentials for ${var.project} ${var.environment} environment"

  tags = {
    Environment = var.environment
    Project     = var.project
    Terraform   = "true"
  }
}

resource "aws_secretsmanager_secret_version" "mongodb" {
  secret_id = aws_secretsmanager_secret.mongodb.id
  secret_string = jsonencode({
    username = var.mongodb_username
    password = var.mongodb_password
    host     = var.mongodb_host
    port     = var.mongodb_port
    database = var.mongodb_database
  })
}

# Secrets Manager Secret for API Keys
resource "aws_secretsmanager_secret" "api_keys" {
  name = "${var.project}-${var.environment}-api-keys"
  description = "API keys for ${var.project} ${var.environment} environment"

  tags = {
    Environment = var.environment
    Project     = var.project
    Terraform   = "true"
  }
}

resource "aws_secretsmanager_secret_version" "api_keys" {
  secret_id = aws_secretsmanager_secret.api_keys.id
  secret_string = jsonencode({
    stripe_secret_key = var.stripe_secret_key
    stripe_publishable_key = var.stripe_publishable_key
    aws_access_key_id = var.aws_access_key_id
    aws_secret_access_key = var.aws_secret_access_key
  })
}

# Outputs
output "database_secret_arn" {
  description = "ARN of the database credentials secret"
  value       = aws_secretsmanager_secret.database.arn
}

output "mongodb_secret_arn" {
  description = "ARN of the MongoDB credentials secret"
  value       = aws_secretsmanager_secret.mongodb.arn
}

output "api_keys_secret_arn" {
  description = "ARN of the API keys secret"
  value       = aws_secretsmanager_secret.api_keys.arn
}

# MongoDB Password Secret
data "aws_secretsmanager_secret" "mongodb_password" {
  name = "finefinds/${var.environment}/mongodb-password"
}

data "aws_secretsmanager_secret_version" "mongodb_password" {
  secret_id = data.aws_secretsmanager_secret.mongodb_password.id
}

resource "aws_secretsmanager_secret" "container_image" {
  name        = "${var.project}/${var.environment}/container-image"
  description = "Container image URI for ${var.environment} environment"
  tags        = var.tags
}

resource "aws_secretsmanager_secret_version" "container_image" {
  secret_id     = aws_secretsmanager_secret.container_image.id
  secret_string = var.container_image
}

output "container_image_arn" {
  description = "ARN of the container image secret"
  value       = aws_secretsmanager_secret.container_image.arn
}

resource "aws_secretsmanager_secret" "db_password" {
  name        = "${var.project}/${var.environment}/db-password"
  description = "Database password for ${var.environment} environment"
  tags        = var.tags
}

resource "aws_secretsmanager_secret_version" "db_password" {
  secret_id     = aws_secretsmanager_secret.db_password.id
  secret_string = var.db_password
}

output "db_password_arn" {
  description = "ARN of the database password secret"
  value       = aws_secretsmanager_secret.db_password.arn
}