variable "project" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where MongoDB will be deployed"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs where MongoDB will be deployed"
  type        = list(string)
}

variable "use_existing_cluster" {
  description = "Whether to use an existing DocumentDB cluster"
  type        = bool
  default     = false
}

variable "use_existing_instance" {
  description = "Whether to use an existing EC2 instance for MongoDB"
  type        = bool
  default     = false
}

variable "existing_security_group_id" {
  description = "Security group ID of the existing DocumentDB cluster"
  type        = string
  default     = ""
}

variable "existing_instance_security_group_id" {
  description = "Security group ID of the existing EC2 instance"
  type        = string
  default     = ""
}

variable "use_existing_subnet_group" {
  description = "Whether to use an existing subnet group"
  type        = bool
  default     = false
}

variable "ami_id" {
  description = "AMI ID for the MongoDB EC2 instance"
  type        = string
  default     = "ami-0c7217cdde317cfec"  # Ubuntu 20.04 LTS
}

variable "instance_type" {
  description = "EC2 instance type for MongoDB"
  type        = string
  default     = "t3.medium"
}

variable "volume_size" {
  description = "Size of the EBS volume in GB"
  type        = number
  default     = 20
}

variable "data_volume_size" {
  description = "Size of the data volume in GB"
  type        = number
  default     = 20
}

variable "admin_username" {
  description = "Admin username for MongoDB"
  type        = string
  default     = "admin"
}

variable "mongodb_password_arn" {
  description = "ARN of the MongoDB password secret in AWS Secrets Manager"
  type        = string
}

variable "existing_cluster_endpoint" {
  description = "Endpoint of the existing DocumentDB cluster"
  type        = string
  default     = ""
}

variable "name" {
  description = "Name of the MongoDB instance"
  type        = string
}

variable "security_group_name" {
  description = "Name of the MongoDB security group"
  type        = string
}

variable "vpc_cidr_blocks" {
  description = "List of VPC CIDR blocks to allow traffic from"
  type        = list(string)
}

variable "instance_class" {
  description = "Instance class for MongoDB"
  type        = string
  default     = "db.t3.medium"
}

variable "allocated_storage" {
  description = "Allocated storage in GB"
  type        = number
  default     = 20
}

variable "skip_final_snapshot" {
  description = "Whether to skip the final snapshot when destroying"
  type        = bool
  default     = true
}

variable "security_group_ids" {
  description = "List of security group IDs to attach to MongoDB"
  type        = list(string)
  default     = []
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