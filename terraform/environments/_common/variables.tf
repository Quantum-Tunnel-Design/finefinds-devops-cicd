variable "project" {
  description = "Project name"
  type        = string
  default     = "finefindslk"
}

variable "environment" {
  description = "Environment name"
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

variable "tags" {
  description = "Additional tags for resources"
  type        = map(string)
  default     = {}
}

# VPC Configuration
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

# Compute Configuration
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

# Database Configuration
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

# Security Configuration
variable "security_config" {
  description = "Security configuration"
  type = object({
    enable_encryption = bool
    enable_backup = bool
    enable_monitoring = bool
  })
}

# Monitoring Configuration
variable "monitoring_config" {
  description = "Monitoring configuration"
  type = object({
    enable_cloudwatch = bool
    enable_xray = bool
    enable_cloudtrail = bool
    log_retention_days = number
  })
} 