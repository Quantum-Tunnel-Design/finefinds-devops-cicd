# Cognito User Pool
resource "aws_cognito_user_pool" "main" {
  name = "${var.project}-${var.environment}-user-pool"

  auto_verified_attributes = ["email"]
  username_attributes      = ["email"]

  password_policy {
    minimum_length    = 8
    require_lowercase = true
    require_numbers   = true
    require_symbols   = true
    require_uppercase = true
  }

  schema {
    attribute_data_type      = "String"
    developer_only_attribute = false
    mutable                  = true
    name                     = "email"
    required                 = true

    string_attribute_constraints {
      min_length = 1
      max_length = 256
    }
  }

  admin_create_user_config {
    allow_admin_create_user_only = false
  }

  tags = {
    Environment = var.environment
    Project     = var.project
    Terraform   = "true"
  }

  lifecycle {
    ignore_changes = [name]
    prevent_destroy = true
  }
}

# Cognito User Pool Client
resource "aws_cognito_user_pool_client" "main" {
  name = "${var.project}-${var.environment}-client"

  user_pool_id = aws_cognito_user_pool.main.id

  generate_secret = true

  explicit_auth_flows = [
    "ALLOW_USER_SRP_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH"
  ]

  callback_urls = var.callback_urls
  logout_urls   = var.logout_urls

  supported_identity_providers = ["COGNITO"]

  token_validity_units {
    refresh_token = "days"
    access_token  = "hours"
    id_token      = "hours"
  }

  refresh_token_validity = 30
  access_token_validity  = 1
  id_token_validity     = 1

  lifecycle {
    ignore_changes = [name]
    prevent_destroy = true
  }
}

# Cognito User Pool Groups
resource "aws_cognito_user_group" "admin" {
  name         = "admin"
  user_pool_id = aws_cognito_user_pool.main.id
  description  = "Administrators"
  precedence   = 1

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_cognito_user_group" "vendor" {
  name         = "vendor"
  user_pool_id = aws_cognito_user_pool.main.id
  description  = "Vendors"
  precedence   = 2

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_cognito_user_group" "parent" {
  name         = "parent"
  user_pool_id = aws_cognito_user_pool.main.id
  description  = "Parents"
  precedence   = 3

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_cognito_user_group" "student" {
  name         = "student"
  user_pool_id = aws_cognito_user_pool.main.id
  description  = "Students"
  precedence   = 4

  lifecycle {
    prevent_destroy = true
  }
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

variable "callback_urls" {
  description = "List of callback URLs"
  type        = list(string)
  default     = ["https://api.finefinds.com/auth/callback"]
}

variable "logout_urls" {
  description = "List of logout URLs"
  type        = list(string)
  default     = ["https://api.finefinds.com/auth/logout"]
}

# Outputs
output "user_pool_id" {
  description = "The ID of the Cognito User Pool"
  value       = aws_cognito_user_pool.main.id
}

output "user_pool_arn" {
  description = "The ARN of the Cognito User Pool"
  value       = aws_cognito_user_pool.main.arn
}

output "client_id" {
  description = "The ID of the Cognito User Pool Client"
  value       = aws_cognito_user_pool_client.main.id
}

output "cognito_client_secret" {
  description = "The client secret of the Cognito User Pool Client"
  value       = aws_cognito_user_pool_client.main.client_secret
  sensitive   = true
} 