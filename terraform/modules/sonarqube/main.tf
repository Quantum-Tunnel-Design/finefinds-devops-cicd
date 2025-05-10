# Get SonarQube database password from Secrets Manager
data "aws_secretsmanager_secret_version" "sonarqube_password" {
  secret_id = var.db_password_arn
}

locals {
  db_password = jsondecode(data.aws_secretsmanager_secret_version.sonarqube_password.secret_string)
}

# ECS Task Definition
resource "aws_ecs_task_definition" "sonarqube" {
  family                   = "${var.project}-${var.environment}-sonarqube"
  requires_compatibilities = ["FARGATE"]
  network_mode            = "awsvpc"
  cpu                     = var.task_cpu
  memory                  = var.task_memory
  execution_role_arn      = var.use_existing_roles ? data.aws_iam_role.ecs_execution_role[0].arn : aws_iam_role.ecs_execution_role[0].arn
  task_role_arn           = var.use_existing_roles ? data.aws_iam_role.ecs_task_role[0].arn : aws_iam_role.ecs_task_role[0].arn

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
          "awslogs-group"         = "/ecs/${var.project}-${var.environment}-sonarqube"
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])

  tags = {
    Environment = var.environment
    Project     = var.project
    Terraform   = "true"
  }
}

# ECS Service
resource "aws_ecs_service" "sonarqube" {
  name            = "${var.project}-${var.environment}-sonarqube"
  cluster         = aws_ecs_cluster.sonarqube.id
  task_definition = aws_ecs_task_definition.sonarqube.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.subnet_ids
    security_groups  = [aws_security_group.sonarqube.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.sonarqube.arn
    container_name   = "sonarqube"
    container_port   = 9000
  }

  tags = {
    Environment = var.environment
    Project     = var.project
    Terraform   = "true"
  }
}

# ECS Cluster
resource "aws_ecs_cluster" "sonarqube" {
  name = "${var.project}-${var.environment}-sonarqube"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = {
    Environment = var.environment
    Project     = var.project
    Terraform   = "true"
  }
}

# Security Group
resource "aws_security_group" "sonarqube" {
  name        = "${var.project}-${var.environment}-sonarqube-sg"
  description = "Security group for SonarQube ECS tasks"
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
    Environment = var.environment
    Project     = var.project
    Terraform   = "true"
  }
}

# Target Group
resource "aws_lb_target_group" "sonarqube" {
  name        = "${var.project}-${var.environment}-sonarqube-tg"
  port        = 9000
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    path                = "/"
    port                = "traffic-port"
    healthy_threshold   = 2
    unhealthy_threshold = 10
    timeout             = 30
    interval            = 60
    matcher             = "200-399"
  }

  tags = {
    Environment = var.environment
    Project     = var.project
    Terraform   = "true"
  }
}

# IAM Roles
resource "aws_iam_role" "ecs_execution_role" {
  count = var.use_existing_roles ? 0 : 1
  name  = "${var.project}-${var.environment}-sonarqube-execution-role"

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
    Terraform   = "true"
  }
}

resource "aws_iam_role_policy_attachment" "ecs_execution_role" {
  count      = var.use_existing_roles ? 0 : 1
  role       = aws_iam_role.ecs_execution_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role" "ecs_task_role" {
  count = var.use_existing_roles ? 0 : 1
  name  = "${var.project}-${var.environment}-sonarqube-task-role"

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
    Terraform   = "true"
  }
}

# Data sources for existing roles
data "aws_iam_role" "ecs_execution_role" {
  count = var.use_existing_roles ? 1 : 0
  name  = "${var.project}-${var.environment}-sonarqube-execution-role"
}

data "aws_iam_role" "ecs_task_role" {
  count = var.use_existing_roles ? 1 : 0
  name  = "${var.project}-${var.environment}-sonarqube-task-role"
}