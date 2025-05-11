variable "project" {
  description = "Project name"
  type        = string
  default     = "finefinds"
}

variable "environment" {
  description = "Environment name (e.g., dev, qa, staging, prod)"
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

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
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