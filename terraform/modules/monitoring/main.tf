# Data source for existing Grafana role
data "aws_iam_role" "existing_grafana" {
  count = var.use_existing_roles ? 1 : 0
  name  = "${var.project}-${var.environment}-grafana"
}

# CloudWatch Dashboard
resource "aws_cloudwatch_dashboard" "main" {
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
            ["AWS/ECS", "CPUUtilization", "ClusterName", "${var.name_prefix}-${var.environment}-cluster"],
            ["AWS/ECS", "MemoryUtilization", "ClusterName", "${var.name_prefix}-${var.environment}-cluster"]
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
  threshold          = local.current_thresholds.cpu_utilization
  alarm_description  = "This metric monitors ECS CPU utilization"
  alarm_actions      = [aws_sns_topic.alerts.arn]
  ok_actions         = [aws_sns_topic.alerts.arn]

  dimensions = {
    ClusterName = "${var.name_prefix}-${var.environment}-cluster"
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
  threshold          = local.current_thresholds.memory_utilization
  alarm_description  = "This metric monitors ECS memory utilization"
  alarm_actions      = [aws_sns_topic.alerts.arn]
  ok_actions         = [aws_sns_topic.alerts.arn]

  dimensions = {
    ClusterName = "${var.name_prefix}-${var.environment}-cluster"
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
  threshold          = local.current_thresholds.rds_cpu
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
  name = "${var.name_prefix}-cloudwatch-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "monitoring.rds.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

# IAM Policy for CloudWatch
resource "aws_iam_role_policy" "cloudwatch" {
  name = "${var.name_prefix}-cloudwatch-policy"
  role = aws_iam_role.cloudwatch.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "cloudwatch:PutMetricData",
          "cloudwatch:GetMetricStatistics",
          "cloudwatch:ListMetrics"
        ]
        Resource = "*"
      }
    ]
  })
}

# CloudWatch Log Groups
resource "aws_cloudwatch_log_group" "alb" {
  name              = "/aws/alb/${var.name_prefix}"
  retention_in_days = var.log_retention_days

  tags = var.tags
}

resource "aws_cloudwatch_log_group" "ecs" {
  name              = "/aws/ecs/${var.name_prefix}"
  retention_in_days = var.log_retention_days

  tags = var.tags
}

resource "aws_cloudwatch_log_group" "rds" {
  name              = "/aws/rds/${var.name_prefix}"
  retention_in_days = var.log_retention_days

  tags = var.tags
}

# CloudWatch Alarms for ALB
resource "aws_cloudwatch_metric_alarm" "alb_5xx" {
  alarm_name          = "${var.name_prefix}-alb-5xx-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "HTTPCode_ELB_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period             = "300"
  statistic          = "Sum"
  threshold          = "10"
  alarm_description  = "This metric monitors ALB 5XX errors"
  alarm_actions      = [aws_sns_topic.alerts.arn]
  ok_actions         = [aws_sns_topic.alerts.arn]

  dimensions = {
    LoadBalancer = "${var.name_prefix}-alb"
  }

  tags = var.tags
}

# X-Ray Group
resource "aws_xray_group" "main" {
  group_name        = "${var.name_prefix}-xray"
  filter_expression = "service(\"${var.name_prefix}\")"

  tags = var.tags
}

# CloudTrail
resource "aws_cloudtrail" "main" {
  name                          = "${var.name_prefix}-trail"
  s3_bucket_name               = aws_s3_bucket.cloudtrail.id
  include_global_service_events = true
  is_multi_region_trail        = true
  enable_logging               = true
  cloud_watch_logs_group_arn   = "${aws_cloudwatch_log_group.cloudtrail.arn}:*"
  cloud_watch_logs_role_arn    = aws_iam_role.cloudtrail.arn

  tags = var.tags
}

# S3 Bucket for CloudTrail
resource "aws_s3_bucket" "cloudtrail" {
  bucket = "${var.name_prefix}-cloudtrail"

  tags = var.tags
}

# S3 Bucket Versioning
resource "aws_s3_bucket_versioning" "cloudtrail" {
  bucket = aws_s3_bucket.cloudtrail.id

  versioning_configuration {
    status = "Enabled"
  }
}

# S3 Bucket Lifecycle Configuration
resource "aws_s3_bucket_lifecycle_configuration" "cloudtrail" {
  bucket = aws_s3_bucket.cloudtrail.id

  rule {
    id     = "cleanup"
    status = "Enabled"

    filter {
      prefix = "AWSLogs/"
    }

    expiration {
      days = 90
    }
  }
}

# S3 Bucket Policy for CloudTrail
data "aws_caller_identity" "current" {}

resource "aws_s3_bucket_policy" "cloudtrail" {
  bucket = aws_s3_bucket.cloudtrail.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid       = "AWSCloudTrailAclCheck",
        Effect    = "Allow",
        Principal = { Service = "cloudtrail.amazonaws.com" },
        Action    = "s3:GetBucketAcl",
        Resource  = aws_s3_bucket.cloudtrail.arn
      },
      {
        Sid       = "AWSCloudTrailWrite",
        Effect    = "Allow",
        Principal = { Service = "cloudtrail.amazonaws.com" },
        Action    = "s3:PutObject",
        Resource  = "${aws_s3_bucket.cloudtrail.arn}/AWSLogs/${data.aws_caller_identity.current.account_id}/*",
        Condition = { StringEquals = { "s3:x-amz-acl" = "bucket-owner-full-control" } }
      }
    ]
  })
}

# IAM Role for CloudTrail
resource "aws_iam_role" "cloudtrail" {
  name = "${var.name_prefix}-cloudtrail-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

# IAM Policy for CloudTrail
resource "aws_iam_role_policy" "cloudtrail" {
  name = "${var.name_prefix}-cloudtrail-policy"
  role = aws_iam_role.cloudtrail.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "${aws_cloudwatch_log_group.cloudtrail.arn}:*"
      }
    ]
  })
}

# CloudWatch Log Group for CloudTrail
resource "aws_cloudwatch_log_group" "cloudtrail" {
  name              = "/aws/cloudtrail/${var.name_prefix}"
  retention_in_days = var.log_retention_days

  tags = var.tags
} 