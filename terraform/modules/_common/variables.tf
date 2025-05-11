# Infrastructure-independent variables
variable "project" {
  description = "Project name"
  type        = string
  default     = "finefindslk"
}

variable "environment" {
  description = "Environment name (e.g., dev, qa, staging, prod)"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "tags" {
  description = "Additional tags for resources"
  type        = map(string)
  default     = {}
}

# Infrastructure-dependent variables (optional)
variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
  default     = null
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs"
  type        = list(string)
  default     = []
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs"
  type        = list(string)
  default     = []
} 