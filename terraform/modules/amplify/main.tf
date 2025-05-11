resource "aws_amplify_app" "client" {
  name        = "${var.project}-${var.environment}-client"
  description = "FineFinds client web application"
  repository  = var.client_repository
  access_token = var.source_token

  # Enable branch auto-build
  enable_branch_auto_build = true

  # Environment variables
  environment_variables = {
    VITE_GRAPHQL_ENDPOINT = var.graphql_endpoint
    VITE_ENVIRONMENT     = var.environment
    VITE_SONARQUBE_URL   = var.sonarqube_url
  }

  # Build settings
  build_spec = <<-EOT
    version: 1
    frontend:
      phases:
        preBuild:
          commands:
            - npm ci
            - npm run lint
            - npm run test
            - |
              if [ -n "$SONAR_TOKEN" ]; then
                npm run sonar
              fi
        build:
          commands:
            - npm run build
      artifacts:
        baseDirectory: dist
        files:
          - '**/*'
      cache:
        paths:
          - node_modules/**/*
  EOT

  tags = merge(var.tags, {
    Name        = "${var.project}-${var.environment}-client"
    Project     = var.project
    Environment = var.environment
  })
}

resource "aws_amplify_app" "admin" {
  name        = "${var.project}-${var.environment}-admin"
  description = "FineFinds admin dashboard"
  repository  = var.admin_repository
  access_token = var.source_token

  # Enable branch auto-build
  enable_branch_auto_build = true

  # Environment variables
  environment_variables = {
    VITE_GRAPHQL_ENDPOINT = var.graphql_endpoint
    VITE_ENVIRONMENT     = var.environment
    VITE_SONARQUBE_URL   = var.sonarqube_url
  }

  # Build settings
  build_spec = <<-EOT
    version: 1
    frontend:
      phases:
        preBuild:
          commands:
            - npm ci
            - npm run lint
            - npm run test
            - |
              if [ -n "$SONAR_TOKEN" ]; then
                npm run sonar
              fi
        build:
          commands:
            - npm run build
      artifacts:
        baseDirectory: dist
        files:
          - '**/*'
      cache:
        paths:
          - node_modules/**/*
  EOT

  tags = merge(var.tags, {
    Name        = "${var.project}-${var.environment}-admin"
    Project     = var.project
    Environment = var.environment
  })
}

# Client app branches
resource "aws_amplify_branch" "client_dev" {
  app_id      = aws_amplify_app.client.id
  branch_name = "dev"
  stage       = "DEVELOPMENT"
  framework   = "React"

  enable_auto_build = true
  enable_performance_mode = true

  environment_variables = {
    VITE_GRAPHQL_ENDPOINT = var.graphql_endpoint
    VITE_ENVIRONMENT     = "dev"
    SONAR_TOKEN          = var.sonar_token
  }
}

resource "aws_amplify_branch" "client_qa" {
  app_id      = aws_amplify_app.client.id
  branch_name = "qa"
  stage       = "BETA"
  framework   = "React"

  enable_auto_build = true
  enable_performance_mode = true

  environment_variables = {
    VITE_GRAPHQL_ENDPOINT = var.graphql_endpoint
    VITE_ENVIRONMENT     = "qa"
    SONAR_TOKEN          = var.sonar_token
  }
}

resource "aws_amplify_branch" "client_staging" {
  app_id      = aws_amplify_app.client.id
  branch_name = "staging"
  stage       = "BETA"
  framework   = "React"

  enable_auto_build = true
  enable_performance_mode = true

  environment_variables = {
    VITE_GRAPHQL_ENDPOINT = var.graphql_endpoint
    VITE_ENVIRONMENT     = "staging"
    SONAR_TOKEN          = var.sonar_token
  }
}

resource "aws_amplify_branch" "client_main" {
  app_id      = aws_amplify_app.client.id
  branch_name = "main"
  stage       = "PRODUCTION"
  framework   = "React"

  enable_auto_build = true
  enable_performance_mode = true

  environment_variables = {
    VITE_GRAPHQL_ENDPOINT = var.graphql_endpoint
    VITE_ENVIRONMENT     = "production"
    SONAR_TOKEN          = var.sonar_token
  }
}

# Admin app branches
resource "aws_amplify_branch" "admin_dev" {
  app_id      = aws_amplify_app.admin.id
  branch_name = "dev"
  stage       = "DEVELOPMENT"
  framework   = "React"

  enable_auto_build = true
  enable_performance_mode = true

  environment_variables = {
    VITE_GRAPHQL_ENDPOINT = var.graphql_endpoint
    VITE_ENVIRONMENT     = "dev"
    SONAR_TOKEN          = var.sonar_token
  }
}

resource "aws_amplify_branch" "admin_qa" {
  app_id      = aws_amplify_app.admin.id
  branch_name = "qa"
  stage       = "BETA"
  framework   = "React"

  enable_auto_build = true
  enable_performance_mode = true

  environment_variables = {
    VITE_GRAPHQL_ENDPOINT = var.graphql_endpoint
    VITE_ENVIRONMENT     = "qa"
    SONAR_TOKEN          = var.sonar_token
  }
}

resource "aws_amplify_branch" "admin_staging" {
  app_id      = aws_amplify_app.admin.id
  branch_name = "staging"
  stage       = "BETA"
  framework   = "React"

  enable_auto_build = true
  enable_performance_mode = true

  environment_variables = {
    VITE_GRAPHQL_ENDPOINT = var.graphql_endpoint
    VITE_ENVIRONMENT     = "staging"
    SONAR_TOKEN          = var.sonar_token
  }
}

resource "aws_amplify_branch" "admin_main" {
  app_id      = aws_amplify_app.admin.id
  branch_name = "main"
  stage       = "PRODUCTION"
  framework   = "React"

  enable_auto_build = true
  enable_performance_mode = true

  environment_variables = {
    VITE_GRAPHQL_ENDPOINT = var.graphql_endpoint
    VITE_ENVIRONMENT     = "production"
    SONAR_TOKEN          = var.sonar_token
  }
}

# Amplify App
resource "aws_amplify_app" "main" {
  name         = var.app_name
  repository   = var.repository
  access_token = var.github_token
  platform     = "WEB"

  # Build settings
  build_spec = <<-EOT
    version: 1
    frontend:
      phases:
        build:
          commands:
            - npm install
            - npm run build
      artifacts:
        baseDirectory: build
        files:
          - '**/*'
      cache:
        paths:
          - node_modules/**/*
  EOT

  tags = var.tags
}

# Amplify Branch
resource "aws_amplify_branch" "main" {
  app_id      = aws_amplify_app.main.id
  branch_name = var.branch

  framework = "React"
  stage     = var.environment == "prod" ? "PRODUCTION" : "DEVELOPMENT"

  enable_auto_build = true
  enable_pull_request_preview = true

  environment_variables = {
    REACT_APP_API_URL = "https://api.${var.project}-${var.environment}.example.com"
  }
}

# IAM Role for Amplify
resource "aws_iam_role" "amplify" {
  count = var.use_existing_roles ? 0 : 1
  name  = "${var.project}-${var.environment}-amplify-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "amplify.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

# IAM Policy for Amplify
resource "aws_iam_role_policy" "amplify" {
  count = var.use_existing_roles ? 0 : 1
  name  = "${var.project}-${var.environment}-amplify-policy"
  role  = aws_iam_role.amplify[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "amplify:*",
          "amplifybackend:*",
          "cloudfront:*",
          "s3:*",
          "iam:*"
        ]
        Resource = "*"
      }
    ]
  })
} 