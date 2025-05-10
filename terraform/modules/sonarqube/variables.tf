variable "project" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where resources will be created"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for the SonarQube instance"
  type        = list(string)
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
  default     = "sonarqube"
}

variable "db_subnet_group_name" {
  description = "Name of the DB subnet group"
  type        = string
}

variable "alb_security_group_id" {
  description = "Security group ID of the ALB"
  type        = string
}

variable "alb_dns_name" {
  description = "DNS name of the ALB"
  type        = string
}

variable "db_endpoint" {
  description = "Endpoint of the SonarQube database"
  type        = string
}

variable "allocated_storage" {
  description = "Allocated storage in GB"
  type        = number
  default     = 20
}

variable "skip_final_snapshot" {
  description = "Skip final snapshot when destroying"
  type        = bool
  default     = false
} 