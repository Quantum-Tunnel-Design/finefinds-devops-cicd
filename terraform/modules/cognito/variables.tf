variable "enable_google_auth" {
  description = "Whether to enable Google authentication"
  type        = bool
  default     = false
}

variable "google_client_id" {
  description = "Google OAuth client ID"
  type        = string
  default     = ""
}

variable "google_client_secret" {
  description = "Google OAuth client secret"
  type        = string
  default     = ""
}

variable "enable_facebook_auth" {
  description = "Whether to enable Facebook authentication"
  type        = bool
  default     = false
}

variable "facebook_client_id" {
  description = "Facebook OAuth client ID"
  type        = string
  default     = ""
}

variable "facebook_client_secret" {
  description = "Facebook OAuth client secret"
  type        = string
  default     = ""
}

variable "certificate_arn" {
  description = "ARN of the certificate for the Cognito domain"
  type        = string
  default     = ""
}

variable "project" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "callback_urls" {
  description = "List of callback URLs"
  type        = list(string)
  default     = ["https://api.finefinds.lk/auth/callback"]
}

variable "logout_urls" {
  description = "List of logout URLs"
  type        = list(string)
  default     = ["https://api.finefinds.lk/auth/logout"]
}

variable "use_existing_roles" {
  description = "Whether to use existing IAM roles"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
} 