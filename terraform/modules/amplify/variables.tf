variable "project" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "client_repository" {
  description = "GitHub repository URL for the client web app"
  type        = string
}

variable "admin_repository" {
  description = "GitHub repository URL for the admin dashboard"
  type        = string
}

variable "source_token" {
  description = "GitHub personal access token for repository access"
  type        = string
  sensitive   = true
}

variable "graphql_endpoint" {
  description = "GraphQL API endpoint URL"
  type        = string
}

variable "sonarqube_url" {
  description = "SonarQube server URL"
  type        = string
}

variable "sonar_token" {
  description = "SonarQube authentication token"
  type        = string
  sensitive   = true
} 