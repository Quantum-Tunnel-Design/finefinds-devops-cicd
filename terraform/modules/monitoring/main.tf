# Data source for existing Grafana role
data "aws_iam_role" "existing_grafana" {
  count = var.use_existing_roles ? 1 : 0
  name  = "${var.project}-${var.environment}-grafana"
}

# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "ecs" {
  name              = "/ecs/${var.project}-${var.environment}"
  retention_in_days = 30

  tags = {
    Environment = var.environment
    Project     = var.project
    Terraform   = "true"
  }

  lifecycle {
    ignore_changes = [name]
  }
}

# CloudWatch Dashboard
resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "${var.project}-${var.environment}-dashboard"

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
            ["AWS/ECS", "CPUUtilization", "ServiceName", "${var.project}-${var.environment}-service", "ClusterName", "${var.project}-${var.environment}-cluster"],
            ["AWS/ECS", "MemoryUtilization", "ServiceName", "${var.project}-${var.environment}-service", "ClusterName", "${var.project}-${var.environment}-cluster"]
          ]
          period = 300
          stat   = "Average"
          region = var.aws_region
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
            ["AWS/RDS", "CPUUtilization", "DBInstanceIdentifier", "${var.project}-${var.environment}-db"],
            ["AWS/RDS", "FreeableMemory", "DBInstanceIdentifier", "${var.project}-${var.environment}-db"]
          ]
          period = 300
          stat   = "Average"
          region = var.aws_region
          title  = "RDS Metrics"
        }
      }
    ]
  })

  tags = var.tags
}

# Prometheus Workspace
resource "aws_prometheus_workspace" "main" {
  alias = "finefinds-${var.environment}"

  tags = {
    Environment = var.environment
  }
}

# Grafana Workspace
resource "aws_grafana_workspace" "main" {
  name                     = "finefinds-${var.environment}"
  account_access_type      = "CURRENT_ACCOUNT"
  authentication_providers = ["AWS_SSO"]
  permission_type         = "SERVICE_MANAGED"
  role_arn                = var.use_existing_roles ? data.aws_iam_role.existing_grafana[0].arn : aws_iam_role.grafana[0].arn

  data_sources = ["PROMETHEUS", "CLOUDWATCH"]

  tags = {
    Environment = var.environment
  }
}

# IAM Role for Grafana
resource "aws_iam_role" "grafana" {
  count = var.use_existing_roles ? 0 : 1
  name  = "${var.project}-${var.environment}-grafana"

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

  tags = {
    Environment = var.environment
    Project     = var.project
    Terraform   = "true"
  }

  lifecycle {
    ignore_changes = [name]
  }
}

# IAM Policy for Grafana
resource "aws_iam_role_policy" "grafana" {
  count = var.use_existing_roles ? 0 : 1
  name  = "grafana-${var.environment}"
  role  = var.use_existing_roles ? data.aws_iam_role.existing_grafana[0].id : aws_iam_role.grafana[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "cloudwatch:GetMetricData",
          "cloudwatch:ListMetrics",
          "cloudwatch:GetMetricStatistics",
          "cloudwatch:DescribeAlarms",
          "aps:QueryMetrics",
          "aps:GetLabels",
          "aps:GetMetricMetadata"
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

# ECS CPU Utilization Alarm
resource "aws_cloudwatch_metric_alarm" "cpu_utilization" {
  alarm_name          = "cpu-utilization-${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period             = "300"
  statistic          = "Average"
  threshold          = local.current_thresholds.cpu_utilization
  alarm_description  = "This metric monitors ECS CPU utilization"
  alarm_actions      = [aws_sns_topic.alerts.arn]
  ok_actions         = [aws_sns_topic.alerts.arn]

  dimensions = {
    ClusterName = "finefinds-${var.environment}"
    ServiceName = "finefinds-${var.environment}"
  }

  tags = {
    Environment = var.environment
    Metric      = "CPUUtilization"
  }
}

# ECS Memory Utilization Alarm
resource "aws_cloudwatch_metric_alarm" "memory_utilization" {
  alarm_name          = "memory-utilization-${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "MemoryUtilization"
  namespace           = "AWS/ECS"
  period             = "300"
  statistic          = "Average"
  threshold          = local.current_thresholds.memory_utilization
  alarm_description  = "This metric monitors ECS memory utilization"
  alarm_actions      = [aws_sns_topic.alerts.arn]
  ok_actions         = [aws_sns_topic.alerts.arn]

  dimensions = {
    ClusterName = "finefinds-${var.environment}"
    ServiceName = "finefinds-${var.environment}"
  }

  tags = {
    Environment = var.environment
    Metric      = "MemoryUtilization"
  }
}

# RDS CPU Utilization Alarm
resource "aws_cloudwatch_metric_alarm" "rds_cpu" {
  alarm_name          = "rds-cpu-utilization-${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period             = "300"
  statistic          = "Average"
  threshold          = local.current_thresholds.rds_cpu
  alarm_description  = "This metric monitors RDS CPU utilization"
  alarm_actions      = [aws_sns_topic.alerts.arn]
  ok_actions         = [aws_sns_topic.alerts.arn]

  dimensions = {
    DBInstanceIdentifier = "finefinds-${var.environment}"
  }

  tags = {
    Environment = var.environment
    Metric      = "RDSCPUUtilization"
  }
}

# RDS Memory Alarm
resource "aws_cloudwatch_metric_alarm" "rds_memory" {
  alarm_name          = "rds-memory-${var.environment}"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "FreeableMemory"
  namespace           = "AWS/RDS"
  period             = "300"
  statistic          = "Average"
  threshold          = local.current_thresholds.rds_memory
  alarm_description  = "This metric monitors RDS freeable memory"
  alarm_actions      = [aws_sns_topic.alerts.arn]
  ok_actions         = [aws_sns_topic.alerts.arn]

  dimensions = {
    DBInstanceIdentifier = "finefinds-${var.environment}"
  }

  tags = {
    Environment = var.environment
    Metric      = "RDSMemory"
  }
}

# Application Error Rate Alarm
resource "aws_cloudwatch_metric_alarm" "error_rate" {
  alarm_name          = "error-rate-${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "ErrorRate"
  namespace           = "FineFinds/Application"
  period             = "300"
  statistic          = "Sum"
  threshold          = local.current_thresholds.error_rate
  alarm_description  = "This metric monitors application error rate"
  alarm_actions      = [aws_sns_topic.alerts.arn]
  ok_actions         = [aws_sns_topic.alerts.arn]

  dimensions = {
    Environment = var.environment
  }

  tags = {
    Environment = var.environment
    Metric      = "ErrorRate"
  }
}

# Application Latency Alarm
resource "aws_cloudwatch_metric_alarm" "latency" {
  alarm_name          = "latency-${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "Latency"
  namespace           = "FineFinds/Application"
  period             = "300"
  statistic          = "Average"
  threshold          = local.current_thresholds.latency
  alarm_description  = "This metric monitors application latency"
  alarm_actions      = [aws_sns_topic.alerts.arn]
  ok_actions         = [aws_sns_topic.alerts.arn]

  dimensions = {
    Environment = var.environment
  }

  tags = {
    Environment = var.environment
    Metric      = "Latency"
  }
}

# SNS Topic for Alerts with Environment-specific Configuration
resource "aws_sns_topic" "alerts" {
  name = "finefinds-alerts-${var.environment}"

  tags = {
    Environment = var.environment
  }
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

# SNS Topic Subscription (example for email)
resource "aws_sns_topic_subscription" "email" {
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