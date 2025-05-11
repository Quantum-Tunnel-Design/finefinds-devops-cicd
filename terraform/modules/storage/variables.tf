variable "project" {
  description = "Project name"
  type        = string
  default     = "finefindslk"
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
  description = "Additional tags for resources"
  type        = map(string)
  default     = {}
}

variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "vpc_cidr_blocks" {
  description = "List of VPC CIDR blocks"
  type        = list(string)
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs"
  type        = list(string)
}

variable "kms_key_id" {
  description = "KMS key ID for encryption"
  type        = string
}

variable "bucket_names" {
  description = "Map of bucket names and their purposes"
  type = map(string)
  default = {
    static  = "static-assets"
    uploads = "uploads"
    backups = "backups"
  }
}

variable "lifecycle_rules" {
  description = "Map of lifecycle rules for each bucket"
  type = map(object({
    enabled = bool
    prefix  = string
    transitions = list(object({
      days          = number
      storage_class = string
    }))
    expiration = object({
      days = number
    })
  }))
  default = {
    uploads = {
      enabled = true
      prefix  = ""
      transitions = [
        {
          days          = 30
          storage_class = "STANDARD_IA"
        },
        {
          days          = 90
          storage_class = "GLACIER"
        }
      ]
      expiration = {
        days = 365
      }
    }
    backups = {
      enabled = true
      prefix  = ""
      transitions = [
        {
          days          = 30
          storage_class = "STANDARD_IA"
        },
        {
          days          = 90
          storage_class = "GLACIER"
        }
      ]
      expiration = {
        days = 365
      }
    }
  }
}

variable "cors_rules" {
  description = "Map of CORS rules for each bucket"
  type = map(object({
    allowed_headers = list(string)
    allowed_methods = list(string)
    allowed_origins = list(string)
    expose_headers  = list(string)
    max_age_seconds = number
  }))
  default = {
    static = {
      allowed_headers = ["*"]
      allowed_methods = ["GET", "HEAD"]
      allowed_origins = ["*"]
      expose_headers  = ["ETag"]
      max_age_seconds = 3000
    }
    uploads = {
      allowed_headers = ["*"]
      allowed_methods = ["GET", "PUT", "POST", "DELETE"]
      allowed_origins = ["*"]
      expose_headers  = ["ETag"]
      max_age_seconds = 3000
    }
  }
}

variable "db_instance_class" {
  description = "Instance class for RDS"
  type        = string
  validation {
    condition     = can(regex("^db\\.[a-z0-9]+\\.[a-z0-9]+$", var.db_instance_class))
    error_message = "The DB instance class must be in the format: db.instance.type (e.g., db.t3.small)."
  }
}

variable "db_name" {
  description = "Name of the RDS database"
  type        = string
  validation {
    condition     = can(regex("^[a-z][a-z0-9_]*$", var.db_name))
    error_message = "The database name must start with a letter and contain only lowercase letters, numbers, and underscores."
  }
}

variable "db_username" {
  description = "Username for RDS database"
  type        = string
  sensitive   = true
  validation {
    condition     = can(regex("^[a-zA-Z][a-zA-Z0-9_]*$", var.db_username))
    error_message = "The database username must start with a letter and contain only letters, numbers, and underscores."
  }
}

variable "db_password" {
  description = "Password for RDS database"
  type        = string
  sensitive   = true
  validation {
    condition     = length(var.db_password) >= 8 && length(var.db_password) <= 128
    error_message = "The database password must be between 8 and 128 characters."
  }
}

variable "allocated_storage" {
  description = "Allocated storage for RDS instance in GB"
  type        = number
  default     = 20
  validation {
    condition     = var.allocated_storage >= 20 && var.allocated_storage <= 65536
    error_message = "The allocated storage must be between 20 and 65536 GB."
  }
}

variable "skip_final_snapshot" {
  description = "Whether to skip final snapshot when destroying the RDS instance"
  type        = bool
  default     = true
}

variable "cloudfront_distribution_arn" {
  description = "ARN of the CloudFront distribution"
  type        = string
  default     = null
} 