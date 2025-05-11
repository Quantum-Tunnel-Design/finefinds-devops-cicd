variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.name_prefix))
    error_message = "The name_prefix must contain only lowercase letters, numbers, and hyphens."
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

variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
  validation {
    condition     = can(regex("^vpc-[a-z0-9]+$", var.vpc_id))
    error_message = "The VPC ID must be in the format: vpc-xxxxxxxx."
  }
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs"
  type        = list(string)
  validation {
    condition     = alltrue([for id in var.private_subnet_ids : can(regex("^subnet-[a-z0-9]+$", id))])
    error_message = "All subnet IDs must be in the format: subnet-xxxxxxxx."
  }
}

variable "vpc_cidr_blocks" {
  description = "List of VPC CIDR blocks for security group rules"
  type        = list(string)
  validation {
    condition     = alltrue([for cidr in var.vpc_cidr_blocks : can(regex("^([0-9]{1,3}\\.){3}[0-9]{1,3}/([0-9]|[1-2][0-9]|3[0-2])$", cidr))])
    error_message = "All CIDR blocks must be in the format: x.x.x.x/x."
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

variable "use_existing_cluster" {
  description = "Whether to use an existing MongoDB cluster"
  type        = bool
  default     = false
}

variable "mongodb_ami" {
  description = "AMI ID for MongoDB instance"
  type        = string
  validation {
    condition     = can(regex("^ami-[a-z0-9]+$", var.mongodb_ami))
    error_message = "The AMI ID must be in the format: ami-xxxxxxxx."
  }
}

variable "mongodb_instance_type" {
  description = "Instance type for MongoDB"
  type        = string
  validation {
    condition     = can(regex("^[a-z0-9]+\\.[a-z0-9]+$", var.mongodb_instance_type))
    error_message = "The instance type must be in the format: type.size (e.g., t3.small)."
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