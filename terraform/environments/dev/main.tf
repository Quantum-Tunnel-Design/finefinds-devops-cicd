provider "aws" {
  region = var.aws_region
}

# Get current AWS account ID
data "aws_caller_identity" "current" {}

# Check if certificate exists
data "aws_acm_certificate" "main" {
  domain      = "${var.environment}.finefinds.com"
  statuses    = ["ISSUED", "PENDING_VALIDATION"]
  most_recent = true
}

# Local variables for certificate handling
locals {
  certificate_arn = data.aws_acm_certificate.main.arn != null ? data.aws_acm_certificate.main.arn : "arn:aws:acm:us-east-1:${data.aws_caller_identity.current.account_id}:certificate/${var.environment}-finefinds-com"
}

# VPC Module
module "vpc" {
  source = "../../modules/vpc"

  project     = var.project
  environment = var.environment
  vpc_cidr    = "10.1.0.0/16"
  availability_zones = ["${var.aws_region}a", "${var.aws_region}b"]
  public_subnet_cidrs  = ["10.1.101.0/24", "10.1.102.0/24"]
  private_subnet_cidrs = ["10.1.1.0/24", "10.1.2.0/24"]
  tags = local.common_tags
}

# Secrets Module
module "secrets" {
  source = "../../modules/secrets"

  project     = var.project
  environment = var.environment
  secret_suffix = var.secret_suffix
  use_existing_secrets = false
  tags = local.common_tags
}

# Security Module
module "security" {
  source = "../../modules/security"

  name_prefix       = local.name_prefix
  tags              = local.common_tags
  callback_urls     = ["https://dev.finefinds.com/callback"]
  logout_urls       = ["https://dev.finefinds.com/logout"]
  certificate_arn   = local.certificate_arn
  db_username       = var.db_username
  db_password       = var.db_password
  mongodb_username  = var.mongodb_username
  mongodb_password  = var.mongodb_password
  sonar_token       = var.sonar_token
  depends_on        = [module.secrets]
}

# Storage Module
module "storage" {
  source                = "../../modules/storage"
  name_prefix           = local.name_prefix
  environment           = var.environment
  vpc_id                = module.vpc.vpc_id
  private_subnet_ids    = module.vpc.private_subnet_ids
  vpc_cidr_blocks       = [local.vpc_cidr]
  db_instance_class     = "db.t3.small"
  db_name               = var.db_name
  db_username           = var.db_username
  db_password           = var.db_password
  use_existing_cluster  = false
  mongodb_ami           = var.mongodb_ami
  mongodb_instance_type = "t3.small"
  allocated_storage     = 50
  skip_final_snapshot   = true
  tags                  = local.common_tags
  depends_on            = [module.vpc, module.security]
}

# Compute Module
module "compute" {
  source                   = "../../modules/compute"
  name_prefix              = local.name_prefix
  environment              = var.environment
  aws_region               = var.aws_region
  vpc_id                   = module.vpc.vpc_id
  public_subnet_ids        = module.vpc.public_subnet_ids
  private_subnet_ids       = module.vpc.private_subnet_ids
  certificate_arn          = local.certificate_arn
  task_cpu                 = 512
  task_memory              = 1024
  task_execution_role_arn  = module.security.ecs_task_execution_role_arn
  task_role_arn            = module.security.ecs_task_role_arn
  container_image          = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com/${module.cicd.ecr_repository_name}"
  container_port           = var.container_port
  container_environment    = []
  service_desired_count    = 2
  rds_secret_arn           = module.security.rds_secret_arn
  mongodb_secret_arn       = module.security.mongodb_secret_arn
  tags                     = local.common_tags
  depends_on               = [module.vpc, module.security, module.storage]
}

# CICD Module
module "cicd" {
  source            = "../../modules/cicd"
  name_prefix       = local.name_prefix
  environment       = var.environment
  repository_url    = var.repository_url
  source_token      = var.source_token
  api_url           = module.compute.alb_dns_name
  cognito_domain    = module.security.cognito_domain
  cognito_client_id = module.security.cognito_user_pool_client_id
  cognito_redirect_uri = "https://dev.finefinds.com/callback"
  domain_name       = "dev.finefinds.com"
  tags              = local.common_tags
  depends_on        = [module.compute]
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
  certificate_arn = local.certificate_arn

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

  task_cpu    = 512
  task_memory = 1024

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
  
  name_prefix       = local.name_prefix
  ecs_cluster_name  = module.ecs.cluster_name
  ecs_service_name  = module.ecs.service_name
  rds_instance_id   = module.rds.db_instance_id
  alb_arn_suffix    = module.alb.alb_arn_suffix

  tags = local.common_tags
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
  default     = "latest"
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

module "networking" {
  source              = "../../modules/networking"
  name_prefix         = local.name_prefix
  vpc_cidr            = var.vpc_cidr
  availability_zones  = var.availability_zones
  tags                = local.common_tags
} 