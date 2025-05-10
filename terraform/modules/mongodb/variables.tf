variable "project" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where resources will be created"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for the MongoDB instance"
  type        = list(string)
}

variable "ecs_security_group_id" {
  description = "Security group ID of the ECS tasks"
  type        = string
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
  description = "Instance type for the MongoDB EC2 instance"
  type        = string
  default     = "t3.micro"
}

variable "volume_size" {
  description = "Size of the root volume in GB"
  type        = number
  default     = 8
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