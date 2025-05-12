variable "project" {
  description = "Project name"
  type        = string
  default     = "finefindslk"
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "tags" {
  description = "Additional tags for resources"
  type        = map(string)
  default     = {}
}

variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs"
  type        = list(string)
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs"
  type        = list(string)
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

variable "service_desired_count" {
  description = "Desired number of tasks"
  type        = number
  default     = 1
}

variable "container_port" {
  description = "Port exposed by the container"
  type        = number
  default     = 3000
}

variable "certificate_arn" {
  description = "ARN of the SSL certificate"
  type        = string
}

variable "rds_secret_arn" {
  description = "ARN of the RDS credentials secret"
  type        = string
}

variable "health_check_path" {
  description = "Path for health checks"
  type        = string
  default     = "/health"
}

variable "health_check_interval" {
  description = "Interval between health checks in seconds"
  type        = number
  default     = 30
}

variable "health_check_timeout" {
  description = "Timeout for health checks in seconds"
  type        = number
  default     = 5
}

variable "health_check_healthy_threshold" {
  description = "Number of consecutive successful health checks required"
  type        = number
  default     = 2
}

variable "health_check_unhealthy_threshold" {
  description = "Number of consecutive failed health checks required"
  type        = number
  default     = 2
}

variable "container_image_arn" {
  description = "ARN of the container image secret in AWS Secrets Manager"
  type        = string
}

variable "alb_target_group_arn" {
  description = "ARN of the ALB Target Group to associate with the ECS service"
  type        = string
}

variable "alb_security_group_id" {
  description = "ID of the ALB Security Group to allow traffic from"
  type        = string
}

variable "container_definitions" {
  description = "JSON-encoded container definitions for ECS task"
  type        = string
}

variable "cpu" {
  description = "Fargate task CPU units"
  type        = number
  default     = 512
}

variable "memory" {
  description = "Fargate task memory in MiB"
  type        = number
  default     = 1024
}

variable "desired_count" {
  description = "Desired number of ECS tasks"
  type        = number
  default     = 2
}

variable "min_capacity" {
  description = "Minimum autoscaling task count"
  type        = number
  default     = 2
}

variable "max_capacity" {
  description = "Maximum autoscaling task count"
  type        = number
  default     = 5
}

variable "assign_public_ip" {
  description = "Whether to assign a public IP to the ECS service"
  type        = bool
  default     = false
}

variable "ecs_task_execution_role_arn" {
  description = "ARN of the ECS task execution role"
  type        = string
}

variable "ecs_task_role_arn" {
  description = "ARN of the ECS task role"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for ECS service"
  type        = list(string)
}
