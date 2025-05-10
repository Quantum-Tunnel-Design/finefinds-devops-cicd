# ECS Task Definition
resource "aws_ecs_task_definition" "sonarqube" {
  family                   = "sonarqube-${var.environment}"
  requires_compatibilities = ["FARGATE"]
  network_mode            = "awsvpc"
  cpu                     = var.task_cpu
  memory                  = var.task_memory
  execution_role_arn      = local.execution_role_arn
  task_role_arn           = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([
    {
      name  = "sonarqube"
      image = "sonarqube:latest"
      portMappings = [
        {
          containerPort = 9000
          hostPort      = 9000
          protocol      = "tcp"
        }
      ]
      environment = [
        {
          name  = "SONAR_JDBC_URL"
          value = "jdbc:postgresql://${var.db_endpoint}:5432/sonarqube"
        },
        {
          name  = "SONAR_JDBC_USERNAME"
          value = var.db_username
        },
        {
          name  = "SONAR_QUALITYGATE_WAIT"
          value = "true"
        },
        {
          name  = "SONAR_QUALITYGATE_TIMEOUT"
          value = "300"
        }
      ]
      secrets = [
        {
          name      = "SONAR_JDBC_PASSWORD"
          valueFrom = aws_secretsmanager_secret.sonarqube_password.arn
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "/ecs/sonarqube-${var.environment}"
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])

  volume {
    name = "sonarqube_data"
    efs_volume_configuration {
      file_system_id          = local.efs_id
      root_directory          = "/"
      transit_encryption      = "ENABLED"
      authorization_config {
        access_point_id = aws_efs_access_point.sonarqube.id
        iam             = "ENABLED"
      }
    }
  }
}

# Data source for existing EFS
data "aws_efs_file_system" "existing" {
  count = var.use_existing_efs ? 1 : 0
  tags = {
    Name = "${var.project}-${var.environment}-sonarqube"
  }
}

# Data source for existing IAM role
data "aws_iam_role" "existing_sonarqube_execution_role" {
  count = var.use_existing_roles ? 1 : 0
  name  = "${var.project}-${var.environment}-sonarqube-execution-role"
}

# EFS File System
resource "aws_efs_file_system" "sonarqube" {
  count = var.use_existing_efs ? 0 : 1
  creation_token = "sonarqube-${var.environment}"

  performance_mode = "generalPurpose"
  throughput_mode  = "bursting"
  encrypted        = true

  tags = {
    Name        = "${var.project}-${var.environment}-sonarqube"
    Environment = var.environment
    Project     = var.project
  }

  lifecycle {
    prevent_destroy = true
  }
}

# Use existing or new EFS
locals {
  efs_id = var.use_existing_efs ? data.aws_efs_file_system.existing[0].id : aws_efs_file_system.sonarqube[0].id
}

resource "aws_efs_access_point" "sonarqube" {
  file_system_id = local.efs_id

  root_directory {
    path = "/sonarqube"
    creation_info {
      owner_gid   = 1000
      owner_uid   = 1000
      permissions = "755"
    }
  }

  posix_user {
    gid = 1000
    uid = 1000
  }

  lifecycle {
    prevent_destroy = true
  }
}

# Generate random password for SonarQube
resource "random_password" "sonarqube_password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

# Store the password in Secrets Manager
resource "aws_secretsmanager_secret" "sonarqube_password" {
  name = "${var.project}-${var.environment}-sonarqube-password"
  description = "SonarQube database password for ${var.environment} environment"

  lifecycle {
    ignore_changes = [name]
    prevent_destroy = true
  }
}

resource "aws_secretsmanager_secret_version" "sonarqube_password" {
  secret_id     = aws_secretsmanager_secret.sonarqube_password.id
  secret_string = random_password.sonarqube_password.result

  lifecycle {
    ignore_changes = [secret_string]
  }
}

# Security Group for SonarQube
resource "aws_security_group" "sonarqube" {
  name        = "${var.project}-${var.environment}-sonarqube"
  description = "Security group for SonarQube"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 9000
    to_port     = 9000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project}-${var.environment}-sonarqube"
    Environment = var.environment
    Project     = var.project
  }

  lifecycle {
    create_before_destroy = true
  }
}

# IAM Role for ECS Task Execution
resource "aws_iam_role" "ecs_execution_role" {
  name = "${var.project}-${var.environment}-sonarqube-execution-role"

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

  tags = {
    Environment = var.environment
    Project     = var.project
  }
}

# Use existing or new execution role
locals {
  execution_role_arn = var.use_existing_roles ? data.aws_iam_role.existing_sonarqube_execution_role[0].arn : aws_iam_role.ecs_execution_role.arn
}

resource "aws_iam_role_policy_attachment" "ecs_execution_role_policy" {
  role       = aws_iam_role.ecs_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# IAM Role for ECS Task
resource "aws_iam_role" "ecs_task_role" {
  name = "${var.project}-${var.environment}-sonarqube-task-role"

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

  tags = {
    Environment = var.environment
    Project     = var.project
  }
} 