variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
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

variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "tags" {
  description = "Additional tags for resources"
  type        = map(string)
  default     = {}
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
    condition     = contains([512, 1024, 2048, 4096, 8192], var.task_memory)
    error_message = "The task memory must be one of: 512, 1024, 2048, 4096, 8192."
  }
}

variable "service_desired_count" {
  description = "Desired number of tasks for the ECS service"
  type        = number
  default     = 1
}

variable "container_image" {
  description = "Container image to deploy"
  type        = string
}

variable "container_port" {
  description = "Port exposed by the container"
  type        = number
  default     = 3000
}

variable "certificate_arn" {
  description = "ARN of the SSL certificate for the ALB"
  type        = string
}

variable "mongodb_secret_arn" {
  description = "ARN of the MongoDB secret"
  type        = string
}

variable "health_check_path" {
  description = "Path for the ALB health check"
  type        = string
  default     = "/health"
}

variable "health_check_interval" {
  description = "Interval for the ALB health check in seconds"
  type        = number
  default     = 30
}

variable "health_check_timeout" {
  description = "Timeout for the ALB health check in seconds"
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