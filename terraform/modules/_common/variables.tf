variable "project" {
  description = "Project name"
  type        = string
  default     = "finefinds"
}

variable "environment" {
  description = "Environment name (e.g., dev, qa, staging, prod)"
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