# This main.tf defines the AWS Secrets Manager secrets that are managed by this module.
# The actual content/values of these secrets are expected to be populated by the
# scripts/generate-secrets.sh script.

# Database credentials secret (composite JSON)
resource "aws_secretsmanager_secret" "database" {
  name        = "${var.project}/${var.environment}/database"
  description = "Database credentials for ${var.project} ${var.environment} (stores {username, password, host, port, database})"
  tags        = var.tags
  # Secret content is managed by generate-secrets.sh
}

# SonarQube Admin Token secret (composite JSON)
resource "aws_secretsmanager_secret" "sonar_token" {
  name        = "${var.project}/${var.environment}/sonar-token"
  description = "SonarQube admin token for ${var.project} ${var.environment} (stores {token})"
  tags        = var.tags
  # Secret content is managed by generate-secrets.sh
}

# Source Control (GitHub PAT) secret (composite JSON)
resource "aws_secretsmanager_secret" "source_token" {
  name        = "${var.project}/${var.environment}/source-token"
  description = "Source control token (e.g., GitHub PAT) for ${var.project} ${var.environment} (stores {token})"
  tags        = var.tags
  # Secret content is managed by generate-secrets.sh
}

# Client Repository URL secret (composite JSON)
resource "aws_secretsmanager_secret" "client_repository" {
  name        = "${var.project}/${var.environment}/client-repository"
  description = "Client repository URL for ${var.project} ${var.environment} (stores {url})"
  tags        = var.tags
  # Secret content is managed by generate-secrets.sh
}

# Admin Repository URL secret (composite JSON)
resource "aws_secretsmanager_secret" "admin_repository" {
  name        = "${var.project}/${var.environment}/admin-repository"
  description = "Admin repository URL for ${var.project} ${var.environment} (stores {url})"
  tags        = var.tags
  # Secret content is managed by generate-secrets.sh
}

# Container Image URI secret (composite JSON)
resource "aws_secretsmanager_secret" "container_image" {
  name        = "${var.project}/${var.environment}/container-image"
  description = "Container image URI for ${var.project} ${var.environment} (stores {image})"
  tags        = var.tags
  # Secret content is managed by generate-secrets.sh
}

# Note: If Terraform were to also manage the *initial version/content* for these secrets,
# you would add aws_secretsmanager_secret_version resources here, populated from variables.
# However, scripts/generate-secrets.sh is currently responsible for content.