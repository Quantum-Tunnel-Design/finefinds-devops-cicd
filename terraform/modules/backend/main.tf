# ECS Cluster
resource "aws_ecs_task_definition" "main" {
  family                   = var.name_prefix
  network_mode            = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                     = var.cpu
  memory                  = var.memory
  execution_role_arn      = var.ecs_task_execution_role_arn
  task_role_arn           = var.ecs_task_role_arn
  container_definitions   = var.container_definitions

  tags = var.tags
}

resource "aws_ecs_service" "main" {
  name            = var.name_prefix
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.main.arn
  desired_count   = var.desired_count
  launch_type     = "FARGATE"
  platform_version = "LATEST"

  network_configuration {
    subnets         = var.subnet_ids
    security_groups = [aws_security_group.service.id]
    assign_public_ip = var.assign_public_ip
  }

  load_balancer {
    target_group_arn = var.alb_target_group_arn
    container_name   = "api"
    container_port   = 4000
  }

  depends_on = [aws_cloudwatch_log_group.main]
  tags = var.tags
}

resource "aws_ecs_cluster" "main" {
  name = var.name_prefix
  tags = var.tags
}

resource "aws_security_group" "service" {
  name        = "${var.name_prefix}-sg"
  description = "Security group for ECS service"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = var.tags
}

resource "aws_appautoscaling_target" "ecs" {
  max_capacity       = var.max_capacity
  min_capacity       = var.min_capacity
  resource_id        = "service/${aws_ecs_cluster.main.name}/${aws_ecs_service.main.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "scale_up" {
  name               = "${var.name_prefix}-scale-up"
  service_namespace  = "ecs"
  resource_id        = aws_appautoscaling_target.ecs.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs.scalable_dimension

  policy_type = "TargetTrackingScaling"
  target_tracking_scaling_policy_configuration {
    target_value       = 50.0
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    scale_in_cooldown  = 300
    scale_out_cooldown = 300
  }
}

resource "aws_cloudwatch_log_group" "main" {
  name              = "/ecs/${var.name_prefix}"
  retention_in_days = 14
  tags              = var.tags
}