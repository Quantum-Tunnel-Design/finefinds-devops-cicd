variable "project" {
  description = "Project name"
  type        = string
  default     = "finefinds"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
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
  description = "Database username"
  type        = string
  sensitive   = true
}

variable "db_password" {
  description = "Database password"
  type        = string
  sensitive   = true
}

variable "sonarqube_db_username" {
  description = "Master username for SonarQube"
  type        = string
  default     = "sonarqube"
}

variable "alert_email" {
  description = "Email for alerts"
  type        = string
}

variable "mongodb_admin_username" {
  description = "MongoDB admin username"
  type        = string
  default     = "admin"
}

variable "mongodb_username" {
  description = "MongoDB username"
  type        = string
  sensitive   = true
}

variable "mongodb_password" {
  description = "MongoDB password"
  type        = string
  sensitive   = true
}

variable "source_token" {
  description = "GitHub personal access token"
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
  description = "SonarQube token for authentication"
  type        = string
  sensitive   = true
}

variable "use_existing_rds_subnet_group" {
  description = "Whether to use an existing RDS subnet group"
  type        = bool
  default     = false
}

variable "use_existing_cluster" {
  description = "Whether to use an existing MongoDB cluster"
  type        = bool
  default     = false
}

variable "use_existing_instance" {
  description = "Whether to use an existing RDS instance"
  type        = bool
  default     = false
}

variable "use_existing_subnet_group" {
  description = "Whether to use an existing subnet group"
  type        = bool
  default     = false
}

variable "use_existing_roles" {
  description = "Whether to use existing IAM roles"
  type        = bool
  default     = false
}

variable "use_existing_secrets" {
  description = "Whether to use existing secrets"
  type        = bool
  default     = false
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs"
  type        = list(string)
  default     = []
}

variable "ecs_security_group_id" {
  description = "Security group ID for ECS tasks"
  type        = string
  default     = ""
}

variable "alb_target_group_arn" {
  description = "ARN of the ALB target group"
  type        = string
  default     = ""
}

variable "allocated_storage" {
  description = "Allocated storage for RDS instance in GB"
  type        = number
  default     = 20
}

variable "use_existing_rds_instance" {
  description = "Whether to use an existing RDS instance"
  type        = bool
  default     = false
}

variable "existing_instance_security_group_id" {
  description = "Security group ID of the existing instance"
  type        = string
  default     = ""
}

variable "existing_security_group_id" {
  description = "Security group ID of the existing resource"
  type        = string
  default     = ""
}

variable "existing_cluster_security_group_id" {
  description = "Security group ID of the existing cluster"
  type        = string
  default     = ""
}

variable "subnet_ids" {
  description = "List of subnet IDs for resources"
  type        = list(string)
  default     = []
}

variable "certificate_arn" {
  description = "ARN of the SSL certificate for the ALB"
  type        = string
  default     = null
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.1.0.0/16"
}

variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "repository_url" {
  description = "URL of the GitHub repository"
  type        = string
}

variable "db_name" {
  description = "Name of the RDS database"
  type        = string
  default     = "finefinds"
}

variable "mongodb_ami" {
  description = "AMI ID for MongoDB instance"
  type        = string
}

variable "container_image" {
  description = "Container image to deploy"
  type        = string
  default     = "amazon/aws-cli:latest"  # Placeholder image
}

variable "callback_urls" {
  description = "Cognito callback URLs"
  type        = list(string)
  default     = ["http://localhost:3000"]
}

variable "logout_urls" {
  description = "Cognito logout URLs"
  type        = list(string)
  default     = ["http://localhost:3000"]
}

variable "db_instance_class" {
  description = "Instance class for the RDS instance"
  type        = string
  default     = "db.t3.micro"
}

variable "skip_final_snapshot" {
  description = "Whether to skip the final snapshot when destroying the RDS instance"
  type        = bool
  default     = false
}

variable "existing_rds_security_group_id" {
  description = "ID of existing RDS security group (optional)"
  type        = string
  default     = null
}

variable "sonarqube_db_password" {
  description = "Password for SonarQube database"
  type        = string
  sensitive   = true
  default     = null
}

variable "tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default     = {
    Project     = "finefinds"
    Environment = "dev"
    ManagedBy   = "Terraform"
  }
}