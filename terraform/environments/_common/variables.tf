variable "project" {
  description = "Project name"
  type        = string
  default     = "finefinds"
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

variable "container_port" {
  description = "Container port"
  type        = number
  default     = 3000
}

variable "db_name" {
  description = "Database name"
  type        = string
}

variable "db_username" {
  description = "Database username"
  type        = string
}

variable "db_password" {
  description = "Database password"
  type        = string
  sensitive   = true
}

variable "mongodb_username" {
  description = "MongoDB username"
  type        = string
}

variable "mongodb_password" {
  description = "MongoDB password"
  type        = string
  sensitive   = true
}

variable "mongodb_ami" {
  description = "MongoDB AMI ID"
  type        = string
}

variable "repository_url" {
  description = "Git repository URL"
  type        = string
}

variable "source_token" {
  description = "Source token for CI/CD"
  type        = string
  sensitive   = true
}

variable "sonar_token" {
  description = "SonarQube token"
  type        = string
  sensitive   = true
} 