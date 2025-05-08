provider "aws" {
  region = var.aws_region
}

# VPC Module
module "vpc" {
  source = "../../modules/vpc"

  project     = var.project
  environment = var.environment

  # Staging uses moderate resources
  vpc_cidr             = "10.1.0.0/16"
  availability_zones   = ["${var.aws_region}a", "${var.aws_region}b"]
  private_subnet_cidrs = ["10.1.1.0/24", "10.1.2.0/24"]
  public_subnet_cidrs  = ["10.1.101.0/24", "10.1.102.0/24"]
}

# ECS Module
module "ecs" {
  source = "../../modules/ecs"

  project     = var.project
  environment = var.environment
  vpc_id      = module.vpc.vpc_id
  subnet_ids  = module.vpc.private_subnet_ids

  # Staging uses moderate resources
  task_cpu            = 512
  task_memory         = 1024
  service_desired_count = 2
  container_name      = var.container_name
  container_port      = var.container_port
  ecr_repository_url  = var.ecr_repository_url
  image_tag           = var.image_tag
  database_url_arn    = var.database_url_arn
  mongodb_uri_arn     = var.mongodb_uri_arn
  alb_security_group_id = var.alb_security_group_id
  aws_region          = var.aws_region
}

# RDS Module
module "rds" {
  source = "../../modules/rds"

  project     = var.project
  environment = var.environment
  vpc_id      = module.vpc.vpc_id
  subnet_ids  = module.vpc.private_subnet_ids

  ecs_security_group_id = module.ecs.ecs_tasks_security_group_id
  db_username          = var.db_username
  db_password          = var.db_password

  # Staging uses moderate resources
  instance_class      = "db.t3.small"
  allocated_storage   = 50
  skip_final_snapshot = false
}

# Cognito Module
module "cognito" {
  source = "../../modules/cognito"

  project     = var.project
  environment = var.environment
}

# S3 Module
module "s3" {
  source = "../../modules/s3"

  project     = var.project
  environment = var.environment
}

# Secrets Manager Module
module "secrets" {
  source = "../../modules/secrets"

  project     = var.project
  environment = var.environment
}

# MongoDB Module
module "mongodb" {
  source = "../../modules/mongodb"

  project     = var.project
  environment = var.environment
  vpc_id      = module.vpc.vpc_id
  subnet_ids  = module.vpc.private_subnet_ids

  # Staging uses moderate resources
  instance_type = "t3.medium"
}

# Monitoring Module
module "monitoring" {
  source = "../../modules/monitoring"

  project     = var.project
  environment = var.environment
  aws_region  = var.aws_region
}

# Variables
variable "project" {
  description = "Project name"
  type        = string
  default     = "finefinds"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "staging"
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "container_name" {
  description = "Name of the container"
  type        = string
  default     = "app"
}

variable "container_port" {
  description = "Port exposed by the container"
  type        = number
  default     = 3000
}

variable "ecr_repository_url" {
  description = "URL of the ECR repository"
  type        = string
}

variable "image_tag" {
  description = "Tag of the container image to deploy"
  type        = string
  default     = "latest"
}

variable "database_url_arn" {
  description = "ARN of the database URL secret"
  type        = string
}

variable "mongodb_uri_arn" {
  description = "ARN of the MongoDB URI secret"
  type        = string
}

variable "alb_security_group_id" {
  description = "Security group ID of the ALB"
  type        = string
}

variable "db_username" {
  description = "Master username for RDS"
  type        = string
}

variable "db_password" {
  description = "Master password for RDS"
  type        = string
  sensitive   = true
}

# Outputs
output "vpc_id" {
  description = "ID of the VPC"
  value       = module.vpc.vpc_id
}

output "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  value       = module.ecs.cluster_name
}

output "ecs_service_name" {
  description = "Name of the ECS service"
  value       = module.ecs.service_name
}

output "rds_endpoint" {
  description = "Endpoint of the RDS instance"
  value       = module.rds.db_instance_endpoint
}

output "cognito_user_pool_id" {
  description = "ID of the Cognito User Pool"
  value       = module.cognito.user_pool_id
}

output "cognito_client_id" {
  description = "ID of the Cognito User Pool Client"
  value       = module.cognito.client_id
}

output "s3_bucket_name" {
  description = "Name of the S3 bucket"
  value       = module.s3.bucket_name
}

output "mongodb_endpoint" {
  description = "Endpoint of the MongoDB instance"
  value       = module.mongodb.endpoint
}

output "cloudwatch_dashboard" {
  description = "Name of the CloudWatch dashboard"
  value       = module.monitoring.dashboard_name
} 