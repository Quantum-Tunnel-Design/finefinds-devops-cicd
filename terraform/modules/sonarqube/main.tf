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

# RDS for SonarQube database
resource "aws_db_instance" "sonarqube" {
  identifier           = "sonarqube-${var.environment}"
  engine              = "postgres"
  engine_version      = "13.7"
  instance_class      = local.config.db_instance_class
  allocated_storage   = 20
  storage_type        = "gp2"
  db_name             = "sonarqube"
  username            = var.db_username
  password            = var.db_password
  skip_final_snapshot = var.environment != "prod"

  vpc_security_group_ids = [aws_security_group.sonarqube_db.id]
  db_subnet_group_name   = var.db_subnet_group_name

  backup_retention_period = local.config.backup_retention
  multi_az               = local.config.multi_az

  tags = {
    Name        = "sonarqube-${var.environment}"
    Environment = var.environment
  }
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