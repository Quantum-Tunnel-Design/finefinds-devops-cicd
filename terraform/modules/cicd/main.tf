# ECR Repository
resource "aws_ecr_repository" "main" {
  name = "finefinds-${var.environment}-repo"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = var.tags
}

# ECR Lifecycle Policy
resource "aws_ecr_lifecycle_policy" "main" {
  repository = aws_ecr_repository.main.name

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

# Amplify App
resource "aws_amplify_app" "main" {
  name = "${var.name_prefix}-app"
  repository = var.repository_url
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

  tags = var.tags
}

# Amplify Branch
resource "aws_amplify_branch" "main" {
  app_id      = aws_amplify_app.main.id
  branch_name = var.environment

  framework = "React"
  stage     = var.environment == "prod" ? "PRODUCTION" : "DEVELOPMENT"

  enable_auto_build = true
  enable_pull_request_preview = true

  environment_variables = {
    REACT_APP_ENV = var.environment
  }

  tags = var.tags
}

# Amplify Domain
resource "aws_amplify_domain_association" "main" {
  app_id      = aws_amplify_app.main.id
  domain_name = var.domain_name

  sub_domain {
    branch_name = aws_amplify_branch.main.branch_name
    prefix      = var.environment
  }

  sub_domain {
    branch_name = aws_amplify_branch.main.branch_name
    prefix      = "www"
  }
} 