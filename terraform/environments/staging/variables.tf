variable "project" {
  description = "Project name"
  type        = string
  default     = "finefindslk"
}

variable "environment" {
  description = "Environment name"
  type        = string
  validation {
    condition     = contains(["dev", "staging", "prod", "qa", "sandbox"], var.environment)
    error_message = "The environment must be one of: dev, staging, prod, qa, sandbox."
  }
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

variable "tags" {
  description = "Additional tags for resources"
  type        = map(string)
  default     = {}
}

variable "certificate_arn" {
  description = "ARN of the SSL certificate"
  type        = string
  default     = null
}

variable "mongodb_secret_arn" {
  description = "ARN of the MongoDB credentials secret"
  type        = string
}

variable "vpc_config" {
  description = "VPC configuration"
  type = object({
    cidr_block           = string
    availability_zones   = list(string)
    public_subnets      = list(string)
    private_subnets     = list(string)
    database_subnets    = list(string)
    enable_nat_gateway  = bool
    single_nat_gateway  = bool
    enable_vpn_gateway  = bool
    enable_flow_log     = bool
    flow_log_retention  = number
  })
}

variable "compute_config" {
  description = "Compute configuration"
  type = object({
    task_cpu    = number
    task_memory = number
    service_desired_count = number
    container_image = string
    container_port  = number
    health_check_path = string
    health_check_interval = number
    health_check_timeout = number
    health_check_healthy_threshold = number
    health_check_unhealthy_threshold = number
  })
}

variable "database_config" {
  description = "Database configuration"
  type = object({
    instance_class = string
    allocated_storage = number
    db_name = string
    backup_retention_period = number
    multi_az = bool
    skip_final_snapshot = bool
    deletion_protection = bool
  })
}

variable "security_config" {
  description = "Security configuration"
  type = object({
    enable_encryption = bool
    enable_backup = bool
    enable_monitoring = bool
  })
}

variable "monitoring_config" {
  description = "Monitoring configuration"
  type = object({
    enable_cloudwatch = bool
    enable_xray = bool
    enable_cloudtrail = bool
    log_retention_days = number
  })
} 