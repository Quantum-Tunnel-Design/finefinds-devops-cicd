variable "project" {
  description = "Project name"
  type        = string
  default     = "finefindslk"
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

variable "image_tag" {
  description = "Tag of the container image to deploy"
  type        = string
  default     = "latest"
}

variable "db_username" {
  description = "Database username"
  type        = string
  default     = null
}

variable "alert_email" {
  description = "Email for alerts"
  type        = string
}

variable "source_token" {
  description = "GitHub source token for repository access"
  type        = string
  sensitive   = true
}

variable "client_repository" {
  description = "URL of the client repository"
  type        = string
}

variable "admin_repository" {
  description = "URL of the admin repository"
  type        = string
}

variable "sonar_token" {
  description = "SonarQube token for authentication"
  type        = string
  sensitive   = true
  default     = null
}

variable "use_existing_rds_subnet_group" {
  description = "Whether to use an existing RDS subnet group"
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
  description = "ARN of the ACM certificate for the custom domain (set to null if using AWS default domains for Cognito/Amplify)"
  type        = string
  # Ensure you have an ACM certificate created in us-east-1 for CloudFront/Cognito custom domains if using a custom domain you own.
  # Example: "arn:aws:acm:us-east-1:123456789012:certificate/your-certificate-id"
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

variable "db_name" {
  description = "Name of the RDS database"
  type        = string
  default     = "finefindslk"
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

variable "tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default     = {
    Project     = "finefindslk"
    Environment = "dev"
    ManagedBy   = "Terraform"
  }
}

variable "client_domain" {
  description = "Client application domain"
  type        = string
  default     = "finefindslk-client-dev.amplifyapp.com"
}

variable "admin_domain" {
  description = "Admin application domain"
  type        = string
  default     = "finefindslk-admin-dev.amplifyapp.com"
}

variable "db_password_arn" {
  description = "ARN of the database password in Secrets Manager"
  type        = string
  default     = null
}

variable "sonar_token_arn" {
  description = "ARN of the SonarQube token in Secrets Manager"
  type        = string
  default     = null
}

variable "db_username_arn" {
  description = "ARN of the database username in Secrets Manager"
  type        = string
  default     = null
}

variable "client_repository_arn" {
  description = "ARN of the client repository URL in Secrets Manager"
  type        = string
  default     = null
}

variable "admin_repository_arn" {
  description = "ARN of the admin repository URL in Secrets Manager"
  type        = string
  default     = null
}

variable "source_token_arn" {
  description = "ARN of the source token in Secrets Manager"
  type        = string
  default     = null
}

variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
  default     = "finefindslk-dev"  # This follows the pattern project-environment
}