# ECS Task Execution Role
resource "aws_iam_role" "ecs_task_execution" {
  name = "${var.name_prefix}-ecs-task-execution"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution" {
  role       = aws_iam_role.ecs_task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# ECS Task Role
resource "aws_iam_role" "ecs_task" {
  name = "${var.name_prefix}-ecs-task"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

# Cognito User Pool
resource "aws_cognito_user_pool" "main" {
  name = "${var.name_prefix}-user-pool"

  auto_verified_attributes = ["email"]
  username_attributes      = ["email"]

  password_policy {
    minimum_length    = 8
    require_lowercase = true
    require_numbers   = true
    require_symbols   = true
    require_uppercase = true
  }

  verification_message_template {
    default_email_option = "CONFIRM_WITH_CODE"
  }

  email_configuration {
    email_sending_account = "COGNITO_DEFAULT"
  }

  admin_create_user_config {
    allow_admin_create_user_only = false
  }

  tags = var.tags
}

# Cognito User Pool Client
resource "aws_cognito_user_pool_client" "main" {
  name                         = "${var.name_prefix}-client"
  user_pool_id                 = aws_cognito_user_pool.main.id
  generate_secret              = true
  refresh_token_validity       = 30
  prevent_user_existence_errors = "ENABLED"
  explicit_auth_flows = [
    "ALLOW_USER_PASSWORD_AUTH",
    "ALLOW_USER_SRP_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH"
  ]

  callback_urls = var.callback_urls
  logout_urls   = var.logout_urls
}

# Cognito User Pool Domain
resource "aws_cognito_user_pool_domain" "main" {
  domain       = "${var.name_prefix}-auth"
  user_pool_id = aws_cognito_user_pool.main.id
  certificate_arn = var.certificate_arn
}

# Secrets for Database Credentials
resource "aws_secretsmanager_secret" "rds" {
  name = "${var.name_prefix}-rds-credentials"
  description = "RDS database credentials"
  tags = var.tags
}

resource "aws_secretsmanager_secret_version" "rds" {
  secret_id = aws_secretsmanager_secret.rds.id
  secret_string = jsonencode({
    username = var.db_username
    password = var.db_password
  })
}

# Secrets for MongoDB Credentials
resource "aws_secretsmanager_secret" "mongodb" {
  name = "${var.name_prefix}-mongodb-credentials"
  description = "MongoDB credentials"
  tags = var.tags
}

resource "aws_secretsmanager_secret_version" "mongodb" {
  secret_id = aws_secretsmanager_secret.mongodb.id
  secret_string = jsonencode({
    username = var.mongodb_username
    password = var.mongodb_password
  })
}

# Secrets for SonarQube Token
resource "aws_secretsmanager_secret" "sonarqube" {
  name = "${var.name_prefix}-sonarqube-token"
  description = "SonarQube authentication token"
  tags = var.tags
}

resource "aws_secretsmanager_secret_version" "sonarqube" {
  secret_id = aws_secretsmanager_secret.sonarqube.id
  secret_string = var.sonar_token
}

# KMS Key
resource "aws_kms_key" "main" {
  count                   = var.enable_encryption ? 1 : 0
  description             = "KMS key for ${var.name_prefix}"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-kms-key"
    }
  )
}

resource "aws_kms_alias" "main" {
  count         = var.enable_encryption ? 1 : 0
  name          = "alias/${var.name_prefix}-kms-key"
  target_key_id = aws_kms_key.main[0].key_id
}

# AWS Backup Vault
resource "aws_backup_vault" "main" {
  count = var.enable_backup ? 1 : 0
  name  = "${var.name_prefix}-backup-vault"

  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-backup-vault"
    }
  )
}

# AWS Backup Plan
resource "aws_backup_plan" "main" {
  count = var.enable_backup ? 1 : 0
  name  = "${var.name_prefix}-backup-plan"

  rule {
    rule_name         = "daily_backups"
    target_vault_name = aws_backup_vault.main[0].name
    schedule          = "cron(0 5 ? * * *)"

    lifecycle {
      delete_after = 30
    }
  }

  rule {
    rule_name         = "weekly_backups"
    target_vault_name = aws_backup_vault.main[0].name
    schedule          = "cron(0 5 ? * 1 *)"

    lifecycle {
      delete_after = 90
    }
  }

  rule {
    rule_name         = "monthly_backups"
    target_vault_name = aws_backup_vault.main[0].name
    schedule          = "cron(0 5 1 * ? *)"

    lifecycle {
      delete_after = 365
    }
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-backup-plan"
    }
  )
}

# AWS Backup IAM Role
resource "aws_iam_role" "backup" {
  count = var.enable_backup ? 1 : 0
  name  = "${var.name_prefix}-backup-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "backup.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-backup-role"
    }
  )
}

resource "aws_iam_role_policy_attachment" "backup" {
  count      = var.enable_backup ? 1 : 0
  role       = aws_iam_role.backup[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForBackup"
}

# CloudWatch Alarm Role
resource "aws_iam_role" "cloudwatch" {
  count = var.enable_monitoring ? 1 : 0
  name  = "${var.name_prefix}-cloudwatch-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "monitoring.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-cloudwatch-role"
    }
  )
}

resource "aws_iam_role_policy_attachment" "cloudwatch" {
  count      = var.enable_monitoring ? 1 : 0
  role       = aws_iam_role.cloudwatch[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonCloudWatchAgentServerPolicy"
}

# CloudWatch Dashboard
resource "aws_cloudwatch_dashboard" "main" {
  count          = var.enable_monitoring ? 1 : 0
  dashboard_name = "${var.name_prefix}-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/ECS", "CPUUtilization", "ServiceName", "${var.name_prefix}-service", "ClusterName", "${var.name_prefix}-cluster"],
            ["AWS/ECS", "MemoryUtilization", "ServiceName", "${var.name_prefix}-service", "ClusterName", "${var.name_prefix}-cluster"]
          ]
          period = 300
          stat   = "Average"
          region = data.aws_region.current.name
          title  = "ECS Service Metrics"
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/RDS", "CPUUtilization", "DBInstanceIdentifier", "${var.name_prefix}-db"],
            ["AWS/RDS", "FreeableMemory", "DBInstanceIdentifier", "${var.name_prefix}-db"]
          ]
          period = 300
          stat   = "Average"
          region = data.aws_region.current.name
          title  = "RDS Metrics"
        }
      }
    ]
  })
}

# Get current region
data "aws_region" "current" {} 