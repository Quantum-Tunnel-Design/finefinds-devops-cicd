provider "aws" {
  region = var.aws_region
}

# Flatten shared inputs via locals
locals {
  vpc_id          = module.vpc.vpc_id
  private_subnets = module.vpc.private_subnet_ids
  public_subnets  = module.vpc.public_subnet_ids
  
  # Shared security group CIDR blocks
  vpc_cidr = "10.0.0.0/16"
  
  # Shared subnet group names
  db_subnet_group_name = "${var.project}-${var.environment}-db-subnet-group"
  
  # Shared tags
  common_tags = {
    Environment = var.environment
    Project     = var.project
    Terraform   = "true"
  }
}

# VPC Module - Foundation for all other modules
module "vpc" {
  source = "../../modules/vpc"

  project     = var.project
  environment = var.environment
  vpc_cidr    = local.vpc_cidr
  availability_zones = ["us-east-1a", "us-east-1b"]
  private_subnet_cidrs = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnet_cidrs  = ["10.0.101.0/24", "10.0.102.0/24"]
}

# Secrets Manager Module - No VPC dependencies
module "secrets" {
  source = "../../modules/secrets"

  project        = var.project
  environment    = var.environment
  secret_suffix  = var.secret_suffix
  use_existing_secrets = true
}

# ALB Module - Depends only on VPC
module "alb" {
  source = "../../modules/alb"

  project     = var.project
  environment = var.environment
  vpc_id      = local.vpc_id
  subnet_ids  = local.public_subnets
  container_port = var.container_port
  name        = local.alb_name
  security_group_name = local.alb_sg_name
  vpc_cidr_blocks = local.vpc_cidr_blocks

  depends_on = [module.vpc]
}

# RDS Module - Depends on VPC and Secrets
module "rds" {
  source = "../../modules/rds"

  project     = var.project
  environment = var.environment
  vpc_id      = local.vpc_id
  subnet_ids  = local.private_subnets
  db_password_arn = module.secrets.database_password_arn
  name        = local.rds_name
  security_group_name = local.rds_sg_name
  vpc_cidr_blocks = local.vpc_cidr_blocks

  depends_on = [module.vpc, module.secrets]
}

# MongoDB Module - Depends on VPC and Secrets
module "mongodb" {
  source = "../../modules/mongodb"

  project     = var.project
  environment = var.environment
  vpc_id      = local.vpc_id
  subnet_ids  = local.private_subnets
  mongodb_password_arn = module.secrets.mongodb_password_arn
  name        = local.mongodb_name
  security_group_name = local.mongo_sg_name
  vpc_cidr_blocks = local.vpc_cidr_blocks

  depends_on = [module.vpc, module.secrets]
}

# ECR Module - No VPC dependencies
module "ecr" {
  source = "../../modules/ecr"

  project     = var.project
  environment = var.environment
}

# ECS Module - Depends on VPC and Secrets
module "ecs" {
  source = "../../modules/ecs"

  project     = var.project
  environment = var.environment
  vpc_id      = local.vpc_id
  private_subnet_ids = local.private_subnets
  aws_region  = var.aws_region
  name        = local.ecs_cluster_name
  security_group_name = local.ecs_sg_name
  vpc_cidr_blocks = local.vpc_cidr_blocks
  database_url_arn = module.secrets.database_secret_arn
  mongodb_uri_arn = module.secrets.mongodb_secret_arn
  ecr_repository_url = module.ecr.repository_url

  depends_on = [module.vpc, module.secrets, module.ecr]
}

# SonarQube Module - Depends on VPC, RDS, and Secrets
module "sonarqube" {
  source = "../../modules/sonarqube"

  project              = var.project
  environment          = var.environment
  vpc_id              = local.vpc_id
  subnet_ids          = local.private_subnets
  aws_region          = var.aws_region
  db_endpoint         = module.rds.endpoint
  db_username         = var.sonarqube_db_username
  db_password_arn     = module.secrets.sonarqube_password_arn
  db_subnet_group_name = local.db_subnet_group_name
  name                = local.sonarqube_name
  security_group_name = local.sonarqube_sg_name
  vpc_cidr_blocks     = local.vpc_cidr_blocks

  depends_on = [module.vpc, module.rds, module.secrets]
}

# Cognito Module - No VPC dependencies
module "cognito" {
  source = "../../modules/cognito"

  project     = var.project
  environment = var.environment
}

# S3 Module - No VPC dependencies
module "s3" {
  source = "../../modules/s3"

  project     = var.project
  environment = var.environment
}

# Monitoring Module - No VPC dependencies
module "monitoring" {
  source = "../../modules/monitoring"

  project     = var.project
  environment = var.environment
  aws_region  = var.aws_region
  alert_email = var.alert_email
}

# Amplify Module - No VPC dependencies
module "amplify" {
  source = "../../modules/amplify"

  project     = var.project
  environment = var.environment
  source_token = var.source_token
  client_repository = var.client_repository
  admin_repository = var.admin_repository
  sonar_token = var.sonar_token
  graphql_endpoint = "https://api.${var.environment}.finefinds.com/graphql"
  sonarqube_url = module.sonarqube.sonarqube_url
}

# Variables
variable "sonarqube_db_password" {
  description = "Password for the SonarQube database"
  type        = string
  sensitive   = true
}

variable "secret_suffix" {
  description = "Suffix for secret names"
  type        = string
  default     = "20250510212247"
}

variable "mongodb_password" {
  description = "Password for the MongoDB instance"
  type        = string
  sensitive   = true
}

# Outputs
output "vpc_id" {
  description = "ID of the VPC"
  value       = local.vpc_id
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