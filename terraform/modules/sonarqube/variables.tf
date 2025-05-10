variable "environment" {
  description = "Environment name"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where resources will be created"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "task_cpu" {
  description = "CPU units for the SonarQube task"
  type        = number
  default     = 1024
}

variable "task_memory" {
  description = "Memory for the SonarQube task"
  type        = number
  default     = 2048
}

variable "db_instance_class" {
  description = "RDS instance class for SonarQube database"
  type        = string
  default     = "db.t3.small"
}

variable "db_username" {
  description = "Username for SonarQube database"
  type        = string
}

variable "db_password" {
  description = "Password for SonarQube database"
  type        = string
  sensitive   = true
}

variable "db_password_arn" {
  description = "ARN of the secret containing the database password"
  type        = string
}

variable "db_subnet_group_name" {
  description = "Name of the DB subnet group"
  type        = string
}

variable "alb_security_group_id" {
  description = "Security group ID of the ALB"
  type        = string
} 