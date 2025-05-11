variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.name_prefix))
    error_message = "The name_prefix must contain only lowercase letters, numbers, and hyphens."
  }
}

variable "project" {
  description = "Project name"
  type        = string
  default     = "finefinds"
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "log_retention_days" {
  description = "Number of days to retain CloudWatch logs"
  type        = number
  default     = 30
}

variable "alert_email" {
  description = "Email address for CloudWatch alerts"
  type        = string
}

variable "evaluation_periods" {
  description = "Number of periods over which the specified statistic is applied"
  type        = number
  default     = 2
  validation {
    condition     = var.evaluation_periods >= 1
    error_message = "The evaluation_periods must be greater than or equal to 1."
  }
}

variable "period" {
  description = "Period in seconds for alarm evaluation"
  type        = number
  default     = 300
  validation {
    condition     = contains([60, 300, 900, 1800, 3600], var.period)
    error_message = "The period must be one of: 60, 300, 900, 1800, 3600 seconds."
  }
}

variable "datapoints_to_alarm" {
  description = "Number of datapoints that must be breaching to trigger the alarm"
  type        = number
  default     = 1
  validation {
    condition     = var.datapoints_to_alarm >= 1
    error_message = "The datapoints_to_alarm must be greater than or equal to 1."
  }
}

variable "treat_missing_data" {
  description = "How to handle missing data points"
  type        = string
  default     = "missing"
  validation {
    condition     = contains(["missing", "notBreaching", "breaching", "ignore"], var.treat_missing_data)
    error_message = "The treat_missing_data must be one of: missing, notBreaching, breaching, ignore."
  }
}

variable "use_existing_roles" {
  description = "Whether to use existing IAM roles"
  type        = bool
  default     = false
}

variable "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  type        = string
  validation {
    condition     = can(regex("^[a-zA-Z0-9-_]+$", var.ecs_cluster_name))
    error_message = "The ECS cluster name must contain only letters, numbers, hyphens, and underscores."
  }
}

variable "ecs_service_name" {
  description = "Name of the ECS service"
  type        = string
  validation {
    condition     = can(regex("^[a-zA-Z0-9-_]+$", var.ecs_service_name))
    error_message = "The ECS service name must contain only letters, numbers, hyphens, and underscores."
  }
}

variable "rds_instance_id" {
  description = "ID of the RDS instance"
  type        = string
  validation {
    condition     = can(regex("^[a-zA-Z0-9-]+$", var.rds_instance_id))
    error_message = "The RDS instance ID must contain only letters, numbers, and hyphens."
  }
}

variable "alb_arn_suffix" {
  description = "ARN suffix of the ALB"
  type        = string
  validation {
    condition     = can(regex("^[a-zA-Z0-9-]+$", var.alb_arn_suffix))
    error_message = "The ALB ARN suffix must contain only letters, numbers, and hyphens."
  }
}

variable "tags" {
  description = "Additional tags for resources"
  type        = map(string)
  default     = {}
}

variable "alarm_thresholds" {
  description = "Thresholds for CloudWatch alarms"
  type = object({
    cpu_utilization    = number
    memory_utilization = number
    disk_utilization   = number
    error_rate        = number
    latency           = number
  })
  default = {
    cpu_utilization    = 80
    memory_utilization = 80
    disk_utilization   = 80
    error_rate        = 5
    latency           = 1000
  }
} 