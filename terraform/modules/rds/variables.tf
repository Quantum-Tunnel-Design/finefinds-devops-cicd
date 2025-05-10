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
  description = "List of subnet IDs for the RDS instance"
  type        = list(string)
}

variable "ecs_security_group_id" {
  description = "Security group ID of the ECS tasks"
  type        = string
}

variable "use_existing_instance" {
  description = "Whether to use an existing RDS instance"
  type        = bool
  default     = false
}

variable "existing_security_group_id" {
  description = "Security group ID of the existing RDS instance"
  type        = string
  default     = ""
}

variable "use_existing_subnet_group" {
  description = "Whether to use an existing subnet group"
  type        = bool
  default     = false
}

variable "db_username" {
  description = "Master username for RDS"
  type        = string
  default     = "admin"
}

variable "db_instance_class" {
  description = "Instance class for the RDS instance"
  type        = string
  default     = "db.t3.micro"
}

variable "allocated_storage" {
  description = "Allocated storage in GB"
  type        = number
  default     = 20
}

variable "skip_final_snapshot" {
  description = "Whether to skip the final snapshot when destroying the instance"
  type        = bool
  default     = true
}

variable "db_name" {
  description = "Name of the database to create"
  type        = string
  default     = "finefinds"
}

variable "db_password_arn" {
  description = "ARN of the database password secret in AWS Secrets Manager"
  type        = string
} 