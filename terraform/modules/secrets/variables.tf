variable "project" {
  description = "Project name (e.g., finefindslk). This is used to construct secret names."
  type        = string
}

variable "environment" {
  description = "Environment name (e.g., dev). This is used to construct secret names."
  type        = string
}

variable "tags" {
  description = "Common tags to apply to all secrets created by this module."
  type        = map(string)
  default     = {}
}

# Note: Other variables related to specific secret values (e.g., db_password, mongodb_username)
# are intentionally omitted here. The scripts/generate-secrets.sh script is now responsible
# for generating and storing the actual secret content in AWS Secrets Manager.
# This Terraform module now primarily defines the secret entities themselves (so their ARNs can be outputted)
# and assumes their content is externally managed by the script.

variable "db_username" {
  description = "Database username"
  type        = string
  default     = ""
}

variable "db_password" {
  description = "Database password to store in AWS Secrets Manager"
  type        = string
}

variable "db_host" {
  description = "Database host"
  type        = string
  default     = ""
}

variable "db_port" {
  description = "Database port"
  type        = number
  default     = 5432
}

variable "db_name" {
  description = "Database name"
  type        = string
  default     = ""
}

variable "mongodb_username" {
  description = "MongoDB username"
  type        = string
  default     = ""
}

variable "mongodb_password" {
  description = "MongoDB password"
  type        = string
  default     = ""
}

variable "mongodb_host" {
  description = "MongoDB host"
  type        = string
  default     = ""
}

variable "mongodb_port" {
  description = "MongoDB port"
  type        = number
  default     = 27017
}

variable "mongodb_database" {
  description = "MongoDB database name"
  type        = string
  default     = ""
}

variable "stripe_secret_key" {
  description = "Stripe secret key"
  type        = string
  default     = ""
}

variable "stripe_publishable_key" {
  description = "Stripe publishable key"
  type        = string
  default     = ""
}

variable "aws_access_key_id" {
  description = "AWS access key ID"
  type        = string
  default     = ""
}

variable "aws_secret_access_key" {
  description = "AWS secret access key"
  type        = string
  default     = ""
}

variable "container_image" {
  description = "Container image URI to store in AWS Secrets Manager"
  type        = string
}

variable "sonarqube_password" {
  description = "Password for SonarQube"
  type        = string
  sensitive   = true
  default     = null
}

variable "source_token" {
  description = "GitHub source token for repository access"
  type        = string
  sensitive   = true
  default     = null
} 