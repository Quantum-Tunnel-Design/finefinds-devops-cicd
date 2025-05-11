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

variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
  validation {
    condition     = can(regex("^vpc-[a-z0-9]+$", var.vpc_id))
    error_message = "The VPC ID must be in the format: vpc-xxxxxxxx."
  }
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs"
  type        = list(string)
  validation {
    condition     = alltrue([for id in var.private_subnet_ids : can(regex("^subnet-[a-z0-9]+$", id))])
    error_message = "All subnet IDs must be in the format: subnet-xxxxxxxx."
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

variable "name" {
  description = "Name of the ECS cluster"
  type        = string
  validation {
    condition     = can(regex("^[a-z][a-z0-9-]*$", var.name))
    error_message = "The cluster name must start with a letter and contain only lowercase letters, numbers, and hyphens."
  }
}

variable "security_group_name" {
  description = "Name of the ECS security group"
  type        = string
  validation {
    condition     = can(regex("^[a-z][a-z0-9-]*$", var.security_group_name))
    error_message = "The security group name must start with a letter and contain only lowercase letters, numbers, and hyphens."
  }
}

variable "vpc_cidr_blocks" {
  description = "List of VPC CIDR blocks to allow traffic from"
  type        = list(string)
  validation {
    condition     = alltrue([for cidr in var.vpc_cidr_blocks : can(regex("^(([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\\.){3}([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])(\\/([0-9]|[1-2][0-9]|3[0-2]))$", cidr))])
    error_message = "All VPC CIDR blocks must be valid IPv4 CIDR blocks."
  }
}

variable "container_port" {
  description = "Port exposed by the container"
  type        = number
  default     = 3000
  validation {
    condition     = var.container_port >= 1 && var.container_port <= 65535
    error_message = "The container port must be between 1 and 65535."
  }
}

variable "database_url_arn" {
  description = "ARN of the database URL secret in AWS Secrets Manager"
  type        = string
  validation {
    condition     = can(regex("^arn:aws:secretsmanager:[a-z0-9-]+:[0-9]+:secret:[a-zA-Z0-9-_/]+$", var.database_url_arn))
    error_message = "The database URL ARN must be a valid Secrets Manager ARN."
  }
}

variable "ecr_repository_url" {
  description = "URL of the ECR repository"
  type        = string
  validation {
    condition     = can(regex("^[0-9]+\\.dkr\\.ecr\\.[a-z0-9-]+\\.amazonaws\\.com/[a-z0-9-]+$", var.ecr_repository_url))
    error_message = "The ECR repository URL must be in the format: account.dkr.ecr.region.amazonaws.com/repository."
  }
}

variable "alb_target_group_arn" {
  description = "ARN of the ALB target group"
  type        = string
  validation {
    condition     = can(regex("^arn:aws:elasticloadbalancing:[a-z0-9-]+:[0-9]+:targetgroup/[a-zA-Z0-9-]+/[a-z0-9]+$", var.alb_target_group_arn))
    error_message = "The ALB target group ARN must be a valid target group ARN."
  }
}

variable "alb_security_group_id" {
  description = "ID of the ALB security group"
  type        = string
  validation {
    condition     = can(regex("^sg-[a-z0-9]+$", var.alb_security_group_id))
    error_message = "The security group ID must be in the format: sg-xxxxxxxx."
  }
}

variable "task_cpu" {
  description = "CPU units for the ECS task"
  type        = number
  default     = 256
  validation {
    condition     = contains([256, 512, 1024, 2048, 4096], var.task_cpu)
    error_message = "The task CPU must be one of: 256, 512, 1024, 2048, 4096."
  }
}

variable "task_memory" {
  description = "Memory for the ECS task in MB"
  type        = number
  default     = 512
  validation {
    condition     = contains([512, 1024, 2048, 4096, 8192, 16384], var.task_memory)
    error_message = "The task memory must be one of: 512, 1024, 2048, 4096, 8192, 16384."
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