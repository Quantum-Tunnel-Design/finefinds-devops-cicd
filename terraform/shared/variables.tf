variable "project" {
  description = "Project name"
  type        = string
  default     = "finefinds"
}

variable "environment" {
  description = "Environment name (sandbox, dev, qa, staging, prod)"
  type        = string
  validation {
    condition     = contains(["sandbox", "dev", "qa", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: sandbox, dev, qa, staging, prod"
  }
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "nonprod_account_id" {
  description = "AWS Account ID for non-prod (sandbox, qa, dev, staging)"
  type        = string
}

variable "prod_account_id" {
  description = "AWS Account ID for production"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b", "us-east-1c"]
}

variable "private_subnet_cidrs" {
  description = "List of private subnet CIDR blocks"
  type        = list(string)
}

variable "public_subnet_cidrs" {
  description = "List of public subnet CIDR blocks"
  type        = list(string)
}

variable "container_port" {
  description = "Port exposed by the container"
  type        = number
  default     = 3000
}

variable "alert_email" {
  description = "Email address for alerts"
  type        = string
}

variable "source_token" {
  description = "GitHub personal access token for repository access"
  type        = string
  sensitive   = true
}

variable "sonar_token" {
  description = "SonarQube authentication token"
  type        = string
  sensitive   = true
}

variable "certificate_arn" {
  description = "ARN of the SSL certificate for the ALB"
  type        = string
} 