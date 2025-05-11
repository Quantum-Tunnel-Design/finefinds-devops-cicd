variable "project" {
  description = "Project name"
  type        = string
  default     = "finefinds"
}

variable "environment" {
  description = "Environment name"
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

variable "callback_urls" {
  description = "List of callback URLs for Cognito"
  type        = list(string)
}

variable "logout_urls" {
  description = "List of logout URLs for Cognito"
  type        = list(string)
}

variable "certificate_arn" {
  description = "ARN of the SSL certificate"
  type        = string
}

variable "db_username" {
  description = "Database username"
  type        = string
}

variable "db_password_arn" {
  description = "ARN of the database password secret in AWS Secrets Manager"
  type        = string
}

variable "mongodb_username" {
  description = "MongoDB username"
  type        = string
}

variable "mongodb_password_arn" {
  description = "ARN of the MongoDB password secret in AWS Secrets Manager"
  type        = string
}

variable "sonar_token_arn" {
  description = "ARN of the SonarQube token secret in AWS Secrets Manager"
  type        = string
}

variable "enable_encryption" {
  description = "Enable KMS encryption"
  type        = bool
  default     = true
}

variable "enable_backup" {
  description = "Enable AWS Backup"
  type        = bool
  default     = true
}

variable "enable_monitoring" {
  description = "Enable CloudWatch monitoring"
  type        = bool
  default     = true
}

variable "client_domain" {
  description = "Client application domain"
  type        = string
}

variable "admin_domain" {
  description = "Admin application domain"
  type        = string
} 