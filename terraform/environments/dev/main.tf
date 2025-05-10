provider "aws" {
  region = var.aws_region
}

# VPC Module
module "vpc" {
  source = "../../modules/vpc"

  project     = var.project
  environment = var.environment

  # Development uses minimal resources but maintains high availability
  vpc_cidr             = "10.3.0.0/16"
  availability_zones   = ["${var.aws_region}a", "${var.aws_region}b"]
  private_subnet_cidrs = ["10.3.1.0/24", "10.3.2.0/24"]
  public_subnet_cidrs  = ["10.3.101.0/24", "10.3.102.0/24"]
}

# ALB Module
module "alb" {
  source = "../../modules/alb"

  project     = var.project
  environment = var.environment
  vpc_id      = module.vpc.vpc_id
  subnet_ids  = module.vpc.public_subnet_ids
  target_group_arn = module.ecs.target_group_arn
}

# ECS Module
module "ecs" {
  source = "../../modules/ecs"

  project     = var.project
  environment = var.environment
  vpc_id      = module.vpc.vpc_id
  subnet_ids  = module.vpc.private_subnet_ids

  # Development uses minimal resources
  task_cpu              = 256
  task_memory           = 512
  service_desired_count = 1
  container_name        = var.container_name
  container_port        = var.container_port
  ecr_repository_url    = var.ecr_repository_url
  image_tag             = var.image_tag
  database_url_arn      = module.rds.db_password_arn
  mongodb_uri_arn       = module.mongodb.mongodb_password_arn
  alb_security_group_id = module.alb.alb_security_group_id
  aws_region            = var.aws_region
}

# RDS Module
module "rds" {
  source = "../../modules/rds"

  project     = var.project
  environment = var.environment
  vpc_id      = module.vpc.vpc_id
  subnet_ids  = module.vpc.private_subnet_ids

  ecs_security_group_id = module.ecs.ecs_tasks_security_group_id
  db_username           = var.db_username
  db_name               = "finefinds"
  db_instance_class     = "db.t3.micro"
  allocated_storage     = 20
  skip_final_snapshot   = true
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

# MongoDB Module
module "mongodb" {
  source = "../../modules/mongodb"

  project               = var.project
  environment           = var.environment
  vpc_id                = module.vpc.vpc_id
  subnet_ids            = module.vpc.private_subnet_ids
  ecs_security_group_id = module.ecs.ecs_tasks_security_group_id
  admin_username        = var.mongodb_admin_username

  # Development uses minimal resources
  instance_type = "t3.micro"
}

# SonarQube Module
module "sonarqube" {
  source = "../../modules/sonarqube"

  project               = var.project
  environment           = var.environment
  vpc_id                = module.vpc.vpc_id
  subnet_ids            = module.vpc.private_subnet_ids
  aws_region            = var.aws_region
  db_instance_class     = "db.t3.small"
  db_username           = var.sonarqube_db_username
  db_subnet_group_name  = module.rds.db_subnet_group_name
  alb_security_group_id = module.alb.alb_security_group_id
  alb_dns_name          = module.alb.alb_dns_name
  db_endpoint           = module.rds.db_instance_endpoint
}

# Monitoring Module
module "monitoring" {
  source = "../../modules/monitoring"

  project     = var.project
  environment = var.environment
  aws_region  = var.aws_region
  alert_email = var.alert_email
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
  default     = "dev"
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
  default     = "123456789012.dkr.ecr.us-east-1.amazonaws.com/finefinds"
}

variable "image_tag" {
  description = "Tag of the container image to deploy"
  type        = string
  default     = "latest"
}

variable "alb_security_group_id" {
  description = "Security group ID of the ALB"
  type        = string
  default     = null
}

variable "db_username" {
  description = "Master username for RDS"
  type        = string
  default     = "admin"
}

variable "sonarqube_db_username" {
  description = "Master username for SonarQube"
  type        = string
  default     = "sonarqube"
}

variable "alert_email" {
  description = "Email address for alerts"
  type        = string
  default     = "amal.c.gamage@gmail.com"
}

variable "mongodb_admin_username" {
  description = "MongoDB admin username"
  type        = string
  default     = "admin"
}

# Outputs
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

output "rds_password_arn" {
  description = "ARN of the RDS password in Secrets Manager"
  value       = module.rds.db_password_arn
  sensitive   = true
}

output "mongodb_password_arn" {
  description = "ARN of the MongoDB password in Secrets Manager"
  value       = module.mongodb.mongodb_password_arn
  sensitive   = true
}

output "sonarqube_password_arn" {
  description = "ARN of the SonarQube password in Secrets Manager"
  value       = module.sonarqube.sonarqube_password_arn
  sensitive   = true
} 