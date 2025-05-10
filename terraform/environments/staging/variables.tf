variable "project" {
  description = "Project name"
  type        = string
  default     = "finefinds"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "staging"
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "container_name" {
  description = "Name of the container"
  type        = string
  default     = "app"
}

variable "container_port" {
  description = "Port exposed by the container"
  type        = number
  default     = 3000
}

variable "ecr_repository_url" {
  description = "URL of the ECR repository"
  type        = string
  default     = "123456789012.dkr.ecr.us-east-1.amazonaws.com/finefinds"
}

variable "image_tag" {
  description = "Tag of the container image to deploy"
  type        = string
  default     = "latest"
}

variable "db_username" {
  description = "Master username for RDS"
  type        = string
  default     = "admin"
}

variable "sonarqube_db_username" {
  description = "Master username for SonarQube"
  type        = string
  default     = "sonarqube"
}

variable "alert_email" {
  description = "Email address for alerts"
  type        = string
  default     = "amal.c.gamage@gmail.com"
}

variable "mongodb_admin_username" {
  description = "MongoDB admin username"
  type        = string
  default     = "admin"
}

variable "source_token" {
  description = "GitHub personal access token for repository access"
  type        = string
  sensitive   = true
}

variable "client_repository" {
  description = "GitHub repository URL for the client web app"
  type        = string
}

variable "admin_repository" {
  description = "GitHub repository URL for the admin dashboard"
  type        = string
}

variable "sonar_token" {
  description = "SonarQube authentication token"
  type        = string
  sensitive   = true
} 