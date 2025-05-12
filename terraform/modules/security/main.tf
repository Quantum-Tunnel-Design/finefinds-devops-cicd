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

resource "aws_iam_role_policy_attachment" "execution" {
  role       = aws_iam_role.ecs_task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
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

# Security Groups
resource "aws_security_group" "db" {
  name        = "${var.name_prefix}-db-sg"
  description = "Security group for database"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/8"]
  }

  tags = var.tags
}

# Get current region
data "aws_region" "current" {}

# Secrets Manager Data Sources

data "aws_secretsmanager_secret_version" "db_credentials" {
  secret_id = var.db_password_arn
}

# Local variables for secrets
locals {
  db_secret_content = jsondecode(data.aws_secretsmanager_secret_version.db_credentials.secret_string)
  db_password       = local.db_secret_content.password
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
  name  = "${var.name_prefix}-backup-plan-${var.environment}"

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
      Name = "${var.name_prefix}-backup-plan-${var.environment}"
    }
  )
}

# AWS Backup IAM Role
resource "aws_iam_role" "backup" {
  count = var.enable_backup ? 1 : 0
  name  = "${var.name_prefix}-backup-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
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
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
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
  dashboard_name = "${var.name_prefix}-${var.environment}-dashboard"

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
            ["AWS/ECS", "CPUUtilization", "ServiceName", "${var.name_prefix}-service", "ClusterName", "${var.name_prefix}-${var.environment}-cluster"],
            ["AWS/ECS", "MemoryUtilization", "ServiceName", "${var.name_prefix}-service", "ClusterName", "${var.name_prefix}-${var.environment}-cluster"]
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