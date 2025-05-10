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
  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.project))
    error_message = "The project name must contain only lowercase letters, numbers, and hyphens."
  }
}

variable "environment" {
  description = "Environment name"
  type        = string
  validation {
    condition     = contains(["dev", "qa", "staging", "prod"], var.environment)
    error_message = "The environment must be one of: dev, qa, staging, prod."
  }
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  validation {
    condition     = can(regex("^[a-z]{2}-[a-z]+-[1-9]$", var.aws_region))
    error_message = "The AWS region must be in the format: xx-xxxxx-N (e.g., us-east-1)."
  }
}

variable "log_retention_days" {
  description = "Number of days to retain CloudWatch logs"
  type        = number
  default     = 30
  validation {
    condition     = var.log_retention_days >= 1 && var.log_retention_days <= 3653
    error_message = "The log retention period must be between 1 and 3653 days."
  }
}

variable "alert_email" {
  description = "Email address for alerts"
  type        = string
  validation {
    condition     = can(regex("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$", var.alert_email))
    error_message = "The alert email must be a valid email address."
  }
}

variable "evaluation_periods" {
  description = "Number of periods to evaluate for alarms"
  type        = number
  default     = 2
  validation {
    condition     = var.evaluation_periods >= 1 && var.evaluation_periods <= 10
    error_message = "The evaluation periods must be between 1 and 10."
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
  default     = 2
  validation {
    condition     = var.datapoints_to_alarm >= 1 && var.datapoints_to_alarm <= var.evaluation_periods
    error_message = "The datapoints to alarm must be between 1 and the number of evaluation periods."
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
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
  validation {
    condition     = alltrue([for k, v in var.tags : can(regex("^[a-zA-Z0-9-_]+$", k)) && can(regex("^[a-zA-Z0-9-_]+$", v))])
    error_message = "Tag keys and values must contain only letters, numbers, hyphens, and underscores."
  }
} 