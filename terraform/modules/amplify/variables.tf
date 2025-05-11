variable "project" {
  description = "Project name"
  type        = string
  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.project))
    error_message = "The project name must contain only lowercase letters, numbers, and hyphens."
  }
}

variable "environment" {
  description = "Environment name"
  type        = string
  validation {
    condition     = contains(["dev", "qa", "staging", "prod"], var.environment)
    error_message = "The environment must be one of: dev, qa, staging, prod."
  }
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  validation {
    condition     = can(regex("^[a-z]{2}-[a-z]+-[1-9]$", var.aws_region))
    error_message = "The AWS region must be in the format: xx-xxxxx-N (e.g., us-east-1)."
  }
}

variable "client_repository" {
  description = "GitHub repository URL for the client application"
  type        = string
  validation {
    condition     = can(regex("^https://github\\.com/[a-zA-Z0-9-]+/[a-zA-Z0-9-_.]+(\\.git)?$", var.client_repository))
    error_message = "The client repository must be a valid GitHub repository URL."
  }
}

variable "admin_repository" {
  description = "GitHub repository URL for the admin application"
  type        = string
  validation {
    condition     = can(regex("^https://github\\.com/[a-zA-Z0-9-]+/[a-zA-Z0-9-_.]+(\\.git)?$", var.admin_repository))
    error_message = "The admin repository must be a valid GitHub repository URL."
  }
}

variable "source_token" {
  description = "GitHub personal access token for repository access"
  type        = string
  sensitive   = true
}

variable "graphql_endpoint" {
  description = "GraphQL API endpoint URL"
  type        = string
  validation {
    condition     = can(regex("^https?://[a-zA-Z0-9.-]+(\\.[a-zA-Z]{2,})+(:[0-9]+)?(/[a-zA-Z0-9._~:/?#\\[\\]@!$&'()*+,;=]*)?$", var.graphql_endpoint))
    error_message = "The GraphQL endpoint must be a valid HTTP(S) URL."
  }
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
  validation {
    condition     = alltrue([for k, v in var.tags : can(regex("^[a-zA-Z0-9-_]+$", k)) && can(regex("^[a-zA-Z0-9-_]+$", v))])
    error_message = "Tag keys and values must contain only letters, numbers, hyphens, and underscores."
  }
}

variable "sonarqube_url" {
  description = "URL of the SonarQube instance"
  type        = string
  default     = ""
  validation {
    condition     = var.sonarqube_url == "" || can(regex("^https?://[a-zA-Z0-9.-]+(\\.[a-zA-Z]{2,})+(:[0-9]+)?(/[a-zA-Z0-9._~:/?#\\[\\]@!$&'()*+,;=]*)?$", var.sonarqube_url))
    error_message = "The SonarQube URL must be a valid HTTP(S) URL or empty."
  }
}

variable "use_existing_roles" {
  description = "Whether to use existing IAM roles"
  type        = bool
  default     = false
}

variable "repository" {
  description = "GitHub repository URL (deprecated, use client_repository and admin_repository instead)"
  type        = string
  default     = ""
  validation {
    condition     = var.repository == "" || can(regex("^https://github\\.com/[a-zA-Z0-9-]+/[a-zA-Z0-9-_.]+(\\.git)?$", var.repository))
    error_message = "The repository must be a valid GitHub repository URL or empty."
  }
}

variable "sonar_token" {
  description = "SonarQube token for authentication"
  type        = string
  sensitive   = true
}

variable "app_name" {
  description = "Name of the Amplify app"
  type        = string
  default     = "finefinds"
}

variable "github_token" {
  description = "GitHub personal access token"
  type        = string
  sensitive   = true
} 