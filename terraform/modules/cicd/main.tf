# ECR Repository for Client
resource "aws_ecr_repository" "client" {
  name = "${var.name_prefix}-client-repo"

  image_scanning_configuration {
    scan_on_push = true
  }
}

# ECR Repository for Admin
resource "aws_ecr_repository" "admin" {
  name = "${var.name_prefix}-admin-repo"

  image_scanning_configuration {
    scan_on_push = true
  }
}

# ECR Lifecycle Policy for Client
resource "aws_ecr_lifecycle_policy" "client" {
  repository = aws_ecr_repository.client.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last 30 images"
        selection = {
          tagStatus     = "any"
          countType     = "imageCountMoreThan"
          countNumber   = 30
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}

# ECR Lifecycle Policy for Admin
resource "aws_ecr_lifecycle_policy" "admin" {
  repository = aws_ecr_repository.admin.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last 30 images"
        selection = {
          tagStatus     = "any"
          countType     = "imageCountMoreThan"
          countNumber   = 30
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}

# Amplify App for Client
resource "aws_amplify_app" "client" {
  name = "${var.name_prefix}-client-app"
  repository = var.client_repository_url
  access_token = var.source_token

  build_spec = <<-EOT
    version: 1
    frontend:
      phases:
        preBuild:
          commands:
            - npm ci
        build:
          commands:
            - npm run build
      artifacts:
        baseDirectory: build
        files:
          - '**/*'
      cache:
        paths:
          - node_modules/**/*
  EOT

  environment_variables = {
    REACT_APP_API_URL = var.api_url
    REACT_APP_AUTH_DOMAIN = var.cognito_domain
    REACT_APP_AUTH_CLIENT_ID = var.cognito_client_id
    REACT_APP_AUTH_REDIRECT_URI = var.cognito_redirect_uri
  }
}

# Amplify App for Admin
resource "aws_amplify_app" "admin" {
  name = "${var.name_prefix}-admin-app"
  repository = var.admin_repository_url
  access_token = var.source_token

  build_spec = <<-EOT
    version: 1
    frontend:
      phases:
        preBuild:
          commands:
            - npm ci
        build:
          commands:
            - npm run build
      artifacts:
        baseDirectory: build
        files:
          - '**/*'
      cache:
        paths:
          - node_modules/**/*
  EOT

  environment_variables = {
    REACT_APP_API_URL = var.api_url
    REACT_APP_AUTH_DOMAIN = var.cognito_domain
    REACT_APP_AUTH_CLIENT_ID = var.cognito_client_id
    REACT_APP_AUTH_REDIRECT_URI = var.cognito_redirect_uri
  }
}

# Amplify Branch for Client
resource "aws_amplify_branch" "client" {
  app_id      = aws_amplify_app.client.id
  branch_name = var.environment

  framework = "React"
  stage     = var.environment == "prod" ? "PRODUCTION" : "DEVELOPMENT"

  enable_auto_build = true
  enable_pull_request_preview = true

  environment_variables = {
    REACT_APP_ENV = var.environment
  }
}

# Amplify Branch for Admin
resource "aws_amplify_branch" "admin" {
  app_id      = aws_amplify_app.admin.id
  branch_name = var.environment

  framework = "React"
  stage     = var.environment == "prod" ? "PRODUCTION" : "DEVELOPMENT"

  enable_auto_build = true
  enable_pull_request_preview = true

  environment_variables = {
    REACT_APP_ENV = var.environment
  }
}

# Note: We're not creating domain associations since we're using AWS default domains
# The apps will be accessible via their default domains:
# - Client: https://{app-id}.amplifyapp.com
# - Admin: https://{app-id}.amplifyapp.com 