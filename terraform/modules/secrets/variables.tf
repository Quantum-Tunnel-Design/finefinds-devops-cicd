variable "db_username" {
  description = "Database username"
  type        = string
  default     = ""
}

variable "db_password" {
  description = "Database password"
  type        = string
  default     = ""
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

variable "project" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "secret_suffix" {
  description = "Suffix for secret names"
  type        = string
}

variable "use_existing_secrets" {
  description = "Whether to use existing secrets"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
} 