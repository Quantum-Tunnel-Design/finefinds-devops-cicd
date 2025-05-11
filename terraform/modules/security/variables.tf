variable "project" {
  description = "Project name"
  type        = string
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
  description = "Common tags for all resources"
  type        = map(string)
}

variable "client_domain" {
  description = "Client application domain"
  type        = string
}

variable "admin_domain" {
  description = "Admin application domain"
  type        = string
}

variable "db_username" {
  description = "Database username"
  type        = string
}

variable "db_password_arn" {
  description = "ARN of the database password in Secrets Manager"
  type        = string
}

variable "mongodb_username" {
  description = "MongoDB username"
  type        = string
}

variable "mongodb_password_arn" {
  description = "ARN of the MongoDB password in Secrets Manager"
  type        = string
}

variable "sonar_token_arn" {
  description = "ARN of the SonarQube token in Secrets Manager"
  type        = string
}

variable "certificate_arn" {
  description = "ARN of the SSL certificate"
  type        = string
}

variable "logout_urls" {
  description = "List of logout URLs for Cognito"
  type        = list(string)
}

variable "callback_urls" {
  description = "List of callback URLs for Cognito"
  type        = list(string)
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