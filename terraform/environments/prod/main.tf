provider "aws" {
  region = var.aws_region
}

# VPC Module
module "vpc" {
  source = "../../modules/vpc"

  project     = var.project
  environment = var.environment

  # Production uses maximum resources
  vpc_cidr             = "10.2.0.0/16"
  availability_zones   = ["${var.aws_region}a", "${var.aws_region}b", "${var.aws_region}c"]
  private_subnet_cidrs = ["10.2.1.0/24", "10.2.2.0/24", "10.2.3.0/24"]
  public_subnet_cidrs  = ["10.2.101.0/24", "10.2.102.0/24", "10.2.103.0/24"]
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

  project            = var.project
  environment        = var.environment
  vpc_id            = module.vpc.vpc_id
  subnet_ids        = module.vpc.private_subnet_ids
  container_name    = var.container_name
  container_port    = var.container_port
  ecr_repository_url = var.ecr_repository_url
  image_tag         = var.image_tag
  alb_security_group_id = module.alb.security_group_id
}

# RDS Module
module "rds" {
  source = "../../modules/rds"

  project     = var.project
  environment = var.environment
  vpc_id      = module.vpc.vpc_id
  subnet_ids  = module.vpc.private_subnet_ids
  ecs_security_group_id = module.ecs.security_group_id
  db_username = var.db_username
  db_instance_class = "db.t3.small"
  allocated_storage = 50
  skip_final_snapshot = false
  db_name = "finefinds"
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
  ecs_security_group_id = module.ecs.security_group_id
  admin_username = var.mongodb_admin_username
}

# Monitoring Module
module "monitoring" {
  source = "../../modules/monitoring"

  project     = var.project
  environment = var.environment
  aws_region  = var.aws_region
  alert_email = var.alert_email
}

# SonarQube Module
module "sonarqube" {
  source = "../../modules/sonarqube"

  project     = var.project
  environment = var.environment
  vpc_id      = module.vpc.vpc_id
  subnet_ids  = module.vpc.private_subnet_ids
  aws_region  = var.aws_region
  db_instance_class = "db.t3.small"
  db_username = var.sonarqube_db_username
  alb_security_group_id = module.alb.security_group_id
  alb_dns_name = module.alb.dns_name
  db_endpoint = module.rds.endpoint
  db_subnet_group_name = module.rds.db_subnet_group_name
}

# Amplify Module
module "amplify" {
  source = "../../modules/amplify"

  project     = var.project
  environment = var.environment
  github_token = var.github_token
  client_repository = var.client_repository
  admin_repository = var.admin_repository
  sonar_token = var.sonar_token
  graphql_endpoint = "https://api.${var.environment}.finefinds.com/graphql"
  sonarqube_url = module.sonarqube.sonarqube_url
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