# This main.tf defines data sources for AWS Secrets Manager secrets that are managed by the
# scripts/generate-secrets.sh script. We use data sources since we're only referencing
# existing secrets, not creating them.

# Database credentials secret
data "aws_secretsmanager_secret" "database" {
  name = "${var.project}/${var.environment}/database"
}

# SonarQube Admin Token secret
data "aws_secretsmanager_secret" "sonar_token" {
  name = "${var.project}/${var.environment}/sonar-token"
}

# Source Control (GitHub PAT) secret
data "aws_secretsmanager_secret" "source_token" {
  name = "${var.project}/${var.environment}/source-token"
}

# Client Repository URL secret
data "aws_secretsmanager_secret" "client_repository" {
  name = "${var.project}/${var.environment}/client-repository"
}

# Admin Repository URL secret
data "aws_secretsmanager_secret" "admin_repository" {
  name = "${var.project}/${var.environment}/admin-repository"
}

# Container Image URI secret
data "aws_secretsmanager_secret" "container_image" {
  name = "${var.project}/${var.environment}/container-image"
}

# Get the latest versions of each secret
data "aws_secretsmanager_secret_version" "database" {
  secret_id = data.aws_secretsmanager_secret.database.id
}

data "aws_secretsmanager_secret_version" "sonar_token" {
  secret_id = data.aws_secretsmanager_secret.sonar_token.id
}

data "aws_secretsmanager_secret_version" "source_token" {
  secret_id = data.aws_secretsmanager_secret.source_token.id
}

data "aws_secretsmanager_secret_version" "client_repository" {
  secret_id = data.aws_secretsmanager_secret.client_repository.id
}

data "aws_secretsmanager_secret_version" "admin_repository" {
  secret_id = data.aws_secretsmanager_secret.admin_repository.id
}

data "aws_secretsmanager_secret_version" "container_image" {
  secret_id = data.aws_secretsmanager_secret.container_image.id
}