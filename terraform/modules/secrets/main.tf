# Reference Secrets from AWS Secrets Manager

data "aws_secretsmanager_secret" "database" {
  name = "${var.project}/${var.environment}/database"
}

data "aws_secretsmanager_secret" "sonar_token" {
  name = "${var.project}/${var.environment}/sonar-token"
}

data "aws_secretsmanager_secret" "source_token" {
  name = "${var.project}/${var.environment}/source-token"
}

data "aws_secretsmanager_secret" "client_repository" {
  name = "${var.project}/${var.environment}/client-repository"
}

data "aws_secretsmanager_secret" "admin_repository" {
  name = "${var.project}/${var.environment}/admin-repository"
}

data "aws_secretsmanager_secret" "container_image" {
  name = "${var.project}/${var.environment}/container-image-new"
}

# Fetch latest secret versions

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