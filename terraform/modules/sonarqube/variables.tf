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

variable "subnet_ids" {
  description = "List of subnet IDs for SonarQube"
  type        = list(string)
}

variable "name" {
  description = "Name of the SonarQube instance"
  type        = string
}

variable "security_group_name" {
  description = "Name of the SonarQube security group"
  type        = string
}

variable "vpc_cidr_blocks" {
  description = "List of VPC CIDR blocks to allow traffic from"
  type        = list(string)
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "db_endpoint" {
  description = "RDS endpoint for SonarQube database"
  type        = string
}

variable "db_username" {
  description = "Username for the SonarQube database"
  type        = string
}

variable "db_password_arn" {
  description = "ARN of the database password secret in AWS Secrets Manager"
  type        = string
}

variable "sonarqube_password_arn" {
  description = "ARN of the SonarQube password secret in AWS Secrets Manager"
  type        = string
}

variable "task_cpu" {
  description = "CPU units for the SonarQube task"
  type        = number
  default     = 256
}

variable "task_memory" {
  description = "Memory for the SonarQube task in MB"
  type        = number
  default     = 512
}

variable "use_existing_efs" {
  description = "Whether to use an existing EFS file system"
  type        = bool
  default     = false
}

variable "use_existing_roles" {
  description = "Whether to use existing IAM roles"
  type        = bool
  default     = false
}

variable "db_subnet_group_name" {
  description = "Name of the DB subnet group"
  type        = string
}

variable "db_instance_class" {
  description = "Instance class for SonarQube database"
  type        = string
  default     = "db.t3.micro"
}

variable "allocated_storage" {
  description = "Allocated storage for SonarQube database in GB"
  type        = number
  default     = 20
}

variable "skip_final_snapshot" {
  description = "Whether to skip final snapshot when destroying"
  type        = bool
  default     = true
}

variable "alb_security_group_id" {
  description = "ID of the ALB security group"
  type        = string
}

variable "alb_dns_name" {
  description = "DNS name of the ALB"
  type        = string
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
} 