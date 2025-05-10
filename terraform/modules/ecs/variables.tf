variable "project" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs"
  type        = list(string)
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "name" {
  description = "Name of the ECS cluster"
  type        = string
}

variable "security_group_name" {
  description = "Name of the ECS security group"
  type        = string
}

variable "vpc_cidr_blocks" {
  description = "List of VPC CIDR blocks to allow traffic from"
  type        = list(string)
}

variable "container_port" {
  description = "Port exposed by the container"
  type        = number
  default     = 3000
}

variable "database_url_arn" {
  description = "ARN of the database URL secret in AWS Secrets Manager"
  type        = string
}

variable "mongodb_uri_arn" {
  description = "ARN of the MongoDB URI secret in AWS Secrets Manager"
  type        = string
}

variable "ecr_repository_url" {
  description = "URL of the ECR repository"
  type        = string
}

variable "alb_target_group_arn" {
  description = "ARN of the ALB target group"
  type        = string
}

variable "alb_security_group_id" {
  description = "ID of the ALB security group"
  type        = string
}

variable "task_cpu" {
  description = "CPU units for the ECS task"
  type        = number
  default     = 256
}

variable "task_memory" {
  description = "Memory for the ECS task in MB"
  type        = number
  default     = 512
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
} 