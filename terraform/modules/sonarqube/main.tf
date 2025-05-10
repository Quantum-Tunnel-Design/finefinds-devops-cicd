resource "aws_ecs_task_definition" "sonarqube" {
  family                   = "sonarqube-${var.environment}"
  requires_compatibilities = ["FARGATE"]
  network_mode            = "awsvpc"
  cpu                     = local.config.task_cpu
  memory                  = local.config.task_memory
  execution_role_arn      = aws_iam_role.ecs_execution_role.arn
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
          valueFrom = var.db_password_arn
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
      file_system_id          = aws_efs_file_system.sonarqube.id
      root_directory          = "/"
      transit_encryption      = "ENABLED"
      authorization_config {
        access_point_id = aws_efs_access_point.sonarqube.id
        iam             = "ENABLED"
      }
    }
  }
}

# EFS for SonarQube data persistence
resource "aws_efs_file_system" "sonarqube" {
  creation_token = "sonarqube-${var.environment}"
  encrypted      = true

  tags = {
    Name        = "sonarqube-${var.environment}"
    Environment = var.environment
  }
}

resource "aws_efs_access_point" "sonarqube" {
  file_system_id = aws_efs_file_system.sonarqube.id

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
  description = "SonarQube password for ${var.environment} environment"
}

resource "aws_secretsmanager_secret_version" "sonarqube_password" {
  secret_id     = aws_secretsmanager_secret.sonarqube_password.id
  secret_string = random_password.sonarqube_password.result
}

# SonarQube RDS Instance
resource "aws_db_instance" "sonarqube" {
  identifier = "${var.project}-${var.environment}-sonarqube"

  engine         = "postgres"
  engine_version = "14.7"
  instance_class = var.db_instance_class

  allocated_storage     = 20
  storage_type         = "gp2"
  storage_encrypted    = true

  db_name  = "sonarqube"
  username = var.db_username
  password = random_password.sonarqube_password.result

  db_subnet_group_name   = var.db_subnet_group_name
  vpc_security_group_ids = [aws_security_group.sonarqube.id]

  backup_retention_period = 7
  skip_final_snapshot    = true

  tags = {
    Environment = var.environment
    Project     = var.project
    Terraform   = "true"
  }
}

# Output the password ARN
output "sonarqube_password_arn" {
  description = "ARN of the SonarQube password in Secrets Manager"
  value       = aws_secretsmanager_secret.sonarqube_password.arn
  sensitive   = true
}

# Security group for SonarQube database
resource "aws_security_group" "sonarqube_db" {
  name        = "sonarqube-db-${var.environment}"
  description = "Security group for SonarQube database"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.sonarqube.id]
  }

  tags = {
    Name        = "sonarqube-db-${var.environment}"
    Environment = var.environment
  }
}

# Security group for SonarQube application
resource "aws_security_group" "sonarqube" {
  name        = "sonarqube-${var.environment}"
  description = "Security group for SonarQube application"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = 9000
    to_port         = 9000
    protocol        = "tcp"
    security_groups = [var.alb_security_group_id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "sonarqube-${var.environment}"
    Environment = var.environment
  }
} 