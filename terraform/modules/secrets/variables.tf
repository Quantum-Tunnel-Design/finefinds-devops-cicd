variable "project" {
  description = "Project name (e.g., finefindslk)"
  type        = string
  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.project))
    error_message = "Project name must contain only lowercase letters, numbers, and hyphens."
  }
}

variable "environment" {
  description = "Environment name (e.g., dev)"
  type        = string
  validation {
    condition     = contains(["dev", "qa", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, qa, staging, prod."
  }
}

variable "tags" {
  description = "Common tags to apply to all secrets used by this module"
  type        = map(string)
  default     = {}
  validation {
    condition     = alltrue([for k, v in var.tags : can(regex("^[a-zA-Z0-9-_]+$", k)) && can(regex("^[a-zA-Z0-9-_]+$", v))])
    error_message = "Tag keys and values must contain only letters, numbers, hyphens, and underscores."
  }
}
