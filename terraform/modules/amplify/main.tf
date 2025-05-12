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
  branch_name = var.environment == "prod" ? "main" : var.environment

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
  branch_name = var.environment == "prod" ? "main" : var.environment

  framework = "React"
  stage     = var.environment == "prod" ? "PRODUCTION" : "DEVELOPMENT"

  enable_auto_build = true
  enable_pull_request_preview = true

  environment_variables = {
    REACT_APP_ENV = var.environment
  }
}

# Amplify Domain for Client
resource "aws_amplify_domain_association" "client" {
  app_id      = aws_amplify_app.client.id
  domain_name = var.domain_name

  sub_domain {
    branch_name = aws_amplify_branch.client.branch_name
    prefix      = var.environment
  }

  sub_domain {
    branch_name = aws_amplify_branch.client.branch_name
    prefix      = "www"
  }
}

# Amplify Domain for Admin
resource "aws_amplify_domain_association" "admin" {
  app_id      = aws_amplify_app.admin.id
  domain_name = var.domain_name

  sub_domain {
    branch_name = aws_amplify_branch.admin.branch_name
    prefix      = "${var.environment}-admin"
  }

  sub_domain {
    branch_name = aws_amplify_branch.admin.branch_name
    prefix      = "admin"
  }
} 