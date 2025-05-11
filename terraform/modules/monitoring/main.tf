# Data source for existing Grafana role
data "aws_iam_role" "existing_grafana" {
  count = var.use_existing_roles ? 1 : 0
  name  = "${var.project}-${var.environment}-grafana"
}

# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "app" {
  name              = "/ecs/${var.name_prefix}"
  retention_in_days = var.environment == "prod" ? 30 : 7

  tags = var.tags
}

# CloudWatch Dashboard
resource "aws_cloudwatch_dashboard" "main" {
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
            ["AWS/ECS", "CPUUtilization", "ClusterName", "${var.name_prefix}-cluster"],
            ["AWS/ECS", "MemoryUtilization", "ClusterName", "${var.name_prefix}-cluster"]
          ]
          period = 300
          stat   = "Average"
          region = var.aws_region
          title  = "ECS Cluster Metrics"
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
            ["AWS/RDS", "CPUUtilization", "DBInstanceIdentifier", "${var.name_prefix}-rds"],
            ["AWS/RDS", "FreeableMemory", "DBInstanceIdentifier", "${var.name_prefix}-rds"]
          ]
          period = 300
          stat   = "Average"
          region = var.aws_region
          title  = "RDS Metrics"
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["AWS/ApplicationELB", "RequestCount", "LoadBalancer", "${var.name_prefix}-alb"],
            ["AWS/ApplicationELB", "TargetResponseTime", "LoadBalancer", "${var.name_prefix}-alb"]
          ]
          period = 300
          stat   = "Sum"
          region = var.aws_region
          title  = "ALB Metrics"
        }
      }
    ]
  })
}

# Prometheus Workspace
resource "aws_prometheus_workspace" "main" {
  alias = "${var.name_prefix}-prometheus"
  tags  = var.tags
}

# Grafana Workspace
resource "aws_grafana_workspace" "main" {
  name                     = "${var.name_prefix}-grafana"
  account_access_type      = "CURRENT_ACCOUNT"
  authentication_providers = ["AWS_SSO"]
  permission_type         = "SERVICE_MANAGED"
  role_arn                = aws_iam_role.grafana.arn

  data_sources = ["PROMETHEUS", "CLOUDWATCH"]

  tags = var.tags
}

# IAM Role for Grafana
resource "aws_iam_role" "grafana" {
  name = "${var.name_prefix}-grafana-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "grafana.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

# IAM Policy for Grafana
resource "aws_iam_role_policy" "grafana" {
  name = "${var.name_prefix}-grafana-policy"
  role = aws_iam_role.grafana.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "aps:QueryMetrics",
          "aps:GetLabels",
          "aps:GetMetricMetadata",
          "aps:GetSeries",
          "cloudwatch:GetMetricData",
          "cloudwatch:ListMetrics",
          "cloudwatch:GetMetricStatistics",
          "cloudwatch:DescribeAlarms"
        ]
        Resource = "*"
      }
    ]
  })
}

# Custom Alerting Thresholds
locals {
  # Environment-specific thresholds
  thresholds = {
    prod = {
      cpu_utilization     = 70
      memory_utilization  = 75
      disk_utilization    = 80
      error_rate          = 1
      latency            = 500
      rds_cpu            = 60
      rds_memory         = 70
      rds_storage        = 80
    }
    staging = {
      cpu_utilization     = 75
      memory_utilization  = 80
      disk_utilization    = 85
      error_rate          = 2
      latency            = 1000
      rds_cpu            = 70
      rds_memory         = 75
      rds_storage        = 85
    }
    dev = {
      cpu_utilization     = 80
      memory_utilization  = 85
      disk_utilization    = 90
      error_rate          = 5
      latency            = 2000
      rds_cpu            = 80
      rds_memory         = 85
      rds_storage        = 90
    }
  }

  # Get thresholds for current environment
  current_thresholds = var.environment == "prod" ? local.thresholds.prod : (var.environment == "staging" ? local.thresholds.staging : local.thresholds.dev)
}

# CloudWatch Alarms
resource "aws_cloudwatch_metric_alarm" "ecs_cpu" {
  alarm_name          = "${var.name_prefix}-ecs-cpu-utilization"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period             = "300"
  statistic          = "Average"
  threshold          = "80"
  alarm_description  = "This metric monitors ECS CPU utilization"
  alarm_actions      = [aws_sns_topic.alerts.arn]
  ok_actions         = [aws_sns_topic.alerts.arn]

  dimensions = {
    ClusterName = "${var.name_prefix}-cluster"
  }

  tags = var.tags
}

resource "aws_cloudwatch_metric_alarm" "ecs_memory" {
  alarm_name          = "${var.name_prefix}-ecs-memory-utilization"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "MemoryUtilization"
  namespace           = "AWS/ECS"
  period             = "300"
  statistic          = "Average"
  threshold          = "80"
  alarm_description  = "This metric monitors ECS memory utilization"
  alarm_actions      = [aws_sns_topic.alerts.arn]
  ok_actions         = [aws_sns_topic.alerts.arn]

  dimensions = {
    ClusterName = "${var.name_prefix}-cluster"
  }

  tags = var.tags
}

resource "aws_cloudwatch_metric_alarm" "rds_cpu" {
  alarm_name          = "${var.name_prefix}-rds-cpu-utilization"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period             = "300"
  statistic          = "Average"
  threshold          = "80"
  alarm_description  = "This metric monitors RDS CPU utilization"
  alarm_actions      = [aws_sns_topic.alerts.arn]
  ok_actions         = [aws_sns_topic.alerts.arn]

  dimensions = {
    DBInstanceIdentifier = "${var.name_prefix}-rds"
  }

  tags = var.tags
}

# SNS Topic for Alerts
resource "aws_sns_topic" "alerts" {
  name = "${var.name_prefix}-alerts"

  tags = var.tags
}

# SNS Topic Policy
resource "aws_sns_topic_policy" "alerts" {
  arn = aws_sns_topic.alerts.arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "cloudwatch.amazonaws.com"
        }
        Action   = "SNS:Publish"
        Resource = aws_sns_topic.alerts.arn
      }
    ]
  })
}

# SNS Topic Subscription
resource "aws_sns_topic_subscription" "alerts" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

# IAM Role for CloudWatch
resource "aws_iam_role" "cloudwatch" {
  count = var.use_existing_roles ? 0 : 1
  name  = "${var.project}-${var.environment}-cloudwatch-role"

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

  tags = var.tags
}

# IAM Policy for CloudWatch
resource "aws_iam_role_policy" "cloudwatch" {
  count = var.use_existing_roles ? 0 : 1
  name  = "${var.project}-${var.environment}-cloudwatch-policy"
  role  = aws_iam_role.cloudwatch[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "cloudwatch:PutMetricData",
          "cloudwatch:GetMetricStatistics",
          "cloudwatch:ListMetrics",
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams"
        ]
        Resource = "*"
      }
    ]
  })
} 