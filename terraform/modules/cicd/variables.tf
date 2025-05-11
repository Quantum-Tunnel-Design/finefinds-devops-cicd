variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "client_repository_url" {
  description = "URL of the client Git repository"
  type        = string
}

variable "admin_repository_url" {
  description = "URL of the admin Git repository"
  type        = string
}

variable "source_token" {
  description = "GitHub personal access token"
  type        = string
  sensitive   = true
}

variable "api_url" {
  description = "URL of the API"
  type        = string
}

variable "cognito_domain" {
  description = "Domain of the Cognito user pool"
  type        = string
}

variable "cognito_client_id" {
  description = "Client ID of the Cognito user pool client"
  type        = string
}

variable "cognito_redirect_uri" {
  description = "Redirect URI for Cognito authentication"
  type        = string
}

variable "domain_name" {
  description = "Domain name for the Amplify app"
  type        = string
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
} 