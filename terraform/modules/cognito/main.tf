# Cognito User Pool - Client
resource "aws_cognito_user_pool" "client_pool" {
  name = "${var.project}-${var.environment}-client-user-pool"

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
  schema {
    attribute_data_type      = "String"
    developer_only_attribute = false
    mutable                  = true
    name                     = "user_type" # Example: parent, student
    required                 = false
    string_attribute_constraints {
      min_length = 1
      max_length = 50
    }
  }

  admin_create_user_config {
    allow_admin_create_user_only = false
  }

  tags = merge(var.tags, { PoolType = "Client" })

  lifecycle {
    prevent_destroy = true
  }
}

# Cognito User Pool - Admin
resource "aws_cognito_user_pool" "admin_pool" {
  name = "${var.project}-${var.environment}-admin-user-pool"

  auto_verified_attributes = ["email"]
  username_attributes      = ["email"]

  password_policy {
    minimum_length    = 10
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
  schema {
    attribute_data_type      = "String"
    developer_only_attribute = false
    mutable                  = true
    name                     = "role" # Example: superadmin, content_manager
    required                 = false
    string_attribute_constraints {
      min_length = 1
      max_length = 50
    }
  }

  admin_create_user_config {
    allow_admin_create_user_only = true
  }

  tags = merge(var.tags, { PoolType = "Admin" })

  lifecycle {
    prevent_destroy = true
  }
}

# Cognito User Pool Client - Client App
resource "aws_cognito_user_pool_client" "client_app" {
  name = "${var.project}-${var.environment}-client-app"
  user_pool_id = aws_cognito_user_pool.client_pool.id
  generate_secret = true # Set to false if it's a public client (e.g., SPA)
  explicit_auth_flows = [
    "ALLOW_USER_PASSWORD_AUTH",
    "ALLOW_USER_SRP_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH"
  ]
  callback_urls = var.callback_urls # Consider var.client_callback_urls
  logout_urls   = var.logout_urls   # Consider var.client_logout_urls
  supported_identity_providers = ["COGNITO"] # Add "Google", "Facebook" if re-configured for client_pool
  token_validity_units {
    access_token  = "hours"
    id_token      = "hours"
    refresh_token = "days"
  }
  access_token_validity  = 1
  id_token_validity     = 1
  refresh_token_validity = 30
  lifecycle {
    prevent_destroy = true
  }
}

# Cognito User Pool Client - Admin App
resource "aws_cognito_user_pool_client" "admin_app" {
  name = "${var.project}-${var.environment}-admin-app"
  user_pool_id = aws_cognito_user_pool.admin_pool.id
  generate_secret = true
  explicit_auth_flows = [
    "ALLOW_ADMIN_USER_PASSWORD_AUTH",
    "ALLOW_USER_PASSWORD_AUTH",
    "ALLOW_USER_SRP_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH"
  ]
  callback_urls = var.callback_urls # Consider var.admin_callback_urls
  logout_urls   = var.logout_urls   # Consider var.admin_logout_urls
  supported_identity_providers = ["COGNITO"]
  token_validity_units {
    access_token  = "hours"
    id_token      = "hours"
    refresh_token = "days"
  }
  access_token_validity  = 1
  id_token_validity     = 1
  refresh_token_validity = 7
  lifecycle {
    prevent_destroy = true
  }
}

# Cognito User Pool Groups
resource "aws_cognito_user_group" "admin_group_for_admin_pool" {
  name         = "admin"
  user_pool_id = aws_cognito_user_pool.admin_pool.id
  description  = "Administrators for Admin Pool"
  precedence   = 1
  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_cognito_user_group" "parent_group_for_client_pool" {
  name         = "parent"
  user_pool_id = aws_cognito_user_pool.client_pool.id
  description  = "Parents for Client Pool"
  precedence   = 1
  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_cognito_user_group" "student_group_for_client_pool" {
  name         = "student"
  user_pool_id = aws_cognito_user_pool.client_pool.id
  description  = "Students for Client Pool"
  precedence   = 2
  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_cognito_user_group" "vendor_group_for_client_pool" {
  name         = "vendor"
  user_pool_id = aws_cognito_user_pool.client_pool.id
  description  = "Vendors for Client Pool"
  precedence   = 3
  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_cognito_user_group" "guest_group_for_client_pool" {
  name         = "guest"
  user_pool_id = aws_cognito_user_pool.client_pool.id
  description  = "Guests for Client Pool"
  precedence   = 4
  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_cognito_user_group" "tutor_group_for_client_pool" {
  name         = "tutor"
  user_pool_id = aws_cognito_user_pool.client_pool.id
  description  = "Tutors for Client Pool"
  precedence   = 5
  lifecycle {
    prevent_destroy = true
  }
}

# Cognito Domain for Client Pool
resource "aws_cognito_user_pool_domain" "client_pool_domain" {
  domain       = "${var.project}-${var.environment}-client"
  user_pool_id = aws_cognito_user_pool.client_pool.id
  # certificate_arn = var.client_pool_certificate_arn # Optional: if using a custom cert for this domain
}

# Cognito Domain for Admin Pool
resource "aws_cognito_user_pool_domain" "admin_pool_domain" {
  domain       = "${var.project}-${var.environment}-admin"
  user_pool_id = aws_cognito_user_pool.admin_pool.id
  # certificate_arn = var.admin_pool_certificate_arn # Optional: if using a custom cert for this domain
}

# Note: Original "main" user pool, its client, domain, and associated Google/Facebook IdPs have been removed.
# If Google/Facebook IdPs are needed, they should be recreated pointing to client_pool or admin_pool,
# and corresponding variables for their client_ids/secrets would need to be managed. 