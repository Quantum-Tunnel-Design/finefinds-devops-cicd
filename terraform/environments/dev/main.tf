provider "aws" {
  region = var.aws_region
}

# VPC Module
module "vpc" {
  source = "../../modules/vpc"

  project     = var.project
  environment = var.environment
  vpc_cidr    = local.vpc_cidr
  availability_zones = local.azs
  public_subnet_cidrs  = local.public_subnet_cidrs
  private_subnet_cidrs = local.private_subnet_cidrs
  tags = local.common_tags
}

# Secrets Module
module "secrets" {
  source = "../../modules/secrets"

  project     = var.project
  environment = var.environment
  secret_suffix = var.secret_suffix
  use_existing_secrets = true
  tags = local.common_tags
}

# ALB Module
module "alb" {
  source = "../../modules/alb"

  project     = var.project
  environment = var.environment
  vpc_id      = module.vpc.vpc_id
  subnet_ids  = module.vpc.public_subnet_ids
  name        = local.alb_name
  security_group_name = local.alb_sg_name
  vpc_cidr_blocks = [local.vpc_cidr]
  container_port = local.container_port
  certificate_arn = var.certificate_arn

  health_check_path     = local.health_check_path
  health_check_port     = local.health_check_port
  health_check_interval = local.health_check_interval
  health_check_timeout  = local.health_check_timeout
  health_check_healthy_threshold   = local.health_check_healthy_threshold
  health_check_unhealthy_threshold = local.health_check_unhealthy_threshold

  tags = local.common_tags
}

# ECR Module
module "ecr" {
  source = "../../modules/ecr"

  project     = var.project
  environment = var.environment
  tags        = local.common_tags
}

# ECS Module
module "ecs" {
  source = "../../modules/ecs"

  project     = var.project
  environment = var.environment
  vpc_id      = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids
  aws_region  = var.aws_region
  name        = local.ecs_cluster_name
  security_group_name = local.ecs_sg_name
  vpc_cidr_blocks = [local.vpc_cidr]

  database_url_arn = module.secrets.database_secret_arn
  mongodb_uri_arn  = module.secrets.mongodb_secret_arn
  ecr_repository_url = module.ecr.repository_url

  alb_target_group_arn = module.alb.target_group_arn
  alb_security_group_id = module.alb.security_group_id

  task_cpu    = local.task_cpu
  task_memory = local.task_memory

  tags = local.common_tags
}

# RDS Module
module "rds" {
  source = "../../modules/rds"

  project     = var.project
  environment = var.environment
  vpc_id      = module.vpc.vpc_id
  subnet_ids  = module.vpc.private_subnet_ids
  name        = local.rds_name
  security_group_name = local.rds_sg_name
  vpc_cidr_blocks = [local.vpc_cidr]

  db_username = local.db_username
  db_name     = local.db_name
  db_password_arn = module.secrets.database_password_arn

  tags = local.common_tags
}

# MongoDB Module
module "mongodb" {
  source = "../../modules/mongodb"

  project     = var.project
  environment = var.environment
  vpc_id      = module.vpc.vpc_id
  subnet_ids  = module.vpc.private_subnet_ids
  name        = local.mongodb_name
  security_group_name = local.mongodb_sg_name
  vpc_cidr_blocks = [local.vpc_cidr]

  mongodb_password_arn = module.secrets.mongodb_password_arn

  tags = local.common_tags
}

# SonarQube Module
module "sonarqube" {
  source = "../../modules/sonarqube"

  project     = var.project
  environment = var.environment
  vpc_id      = module.vpc.vpc_id
  subnet_ids  = module.vpc.private_subnet_ids
  name        = local.sonarqube_name
  security_group_name = local.sonarqube_sg_name
  vpc_cidr_blocks = [local.vpc_cidr]

  aws_region = var.aws_region
  alb_security_group_id = module.alb.security_group_id
  alb_dns_name = module.alb.alb_dns_name

  db_endpoint = module.rds.db_instance_endpoint
  db_username = local.db_username
  db_password_arn = module.secrets.database_password_arn
  sonarqube_password_arn = module.secrets.sonarqube_password_arn
  db_subnet_group_name = module.rds.db_subnet_group_name

  task_cpu    = local.task_cpu
  task_memory = local.task_memory

  tags = local.common_tags
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

# Amplify Module
module "amplify" {
  source = "../../modules/amplify"

  project     = var.project
  environment = var.environment
  aws_region  = var.aws_region

  client_repository = var.client_repository
  admin_repository  = var.admin_repository
  source_token     = var.source_token
  graphql_endpoint = "https://api.${var.environment}.finefinds.com/graphql"

  tags = local.common_tags
}

# Variables
variable "secret_suffix" {
  description = "Suffix for secret names"
  type        = string
  default     = "20250510212247"
}

# Outputs
output "vpc_id" {
  description = "ID of the VPC"
  value       = module.vpc.vpc_id
}

output "alb_dns_name" {
  description = "DNS name of the ALB"
  value       = module.alb.alb_dns_name
}

output "sonarqube_url" {
  description = "URL of the SonarQube instance"
  value       = module.sonarqube.sonarqube_url
}

output "ecr_repository_url" {
  description = "URL of the ECR repository"
  value       = module.ecr.repository_url
}

output "rds_security_group_id" {
  description = "ID of the RDS security group"
  value       = module.rds.security_group_id
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