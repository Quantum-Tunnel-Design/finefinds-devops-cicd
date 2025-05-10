variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "callback_urls" {
  description = "List of callback URLs for Cognito client"
  type        = list(string)
  default     = []
}

variable "logout_urls" {
  description = "List of logout URLs for Cognito client"
  type        = list(string)
  default     = []
}

variable "certificate_arn" {
  description = "ARN of the SSL certificate for Cognito domain"
  type        = string
}

variable "db_username" {
  description = "Username for RDS database"
  type        = string
  sensitive   = true
}

variable "db_password" {
  description = "Password for RDS database"
  type        = string
  sensitive   = true
}

variable "mongodb_username" {
  description = "Username for MongoDB"
  type        = string
  sensitive   = true
}

variable "mongodb_password" {
  description = "Password for MongoDB"
  type        = string
  sensitive   = true
}

variable "sonar_token" {
  description = "SonarQube authentication token"
  type        = string
  sensitive   = true
} 