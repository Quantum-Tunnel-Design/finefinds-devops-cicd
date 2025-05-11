provider "aws" {
  region = var.aws_region
}

# Get current AWS account ID
data "aws_caller_identity" "current" {}

# Local variables for domains
locals {
  client_domain = "${var.project}-client-${var.environment}.amplifyapp.com"
  admin_domain = "${var.project}-admin-${var.environment}.amplifyapp.com"
  graphql_endpoint = "https://${local.client_domain}/graphql"
}

# Use common module for standard variables
module "common" {
  source = "../../modules/_common"

  project     = var.project
  environment = var.environment
  aws_region  = var.aws_region
  vpc_id      = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids
  public_subnet_ids  = module.vpc.public_subnet_ids
  tags        = var.tags
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
  tags        = var.tags
}

# Secrets Module
module "secrets" {
  source = "../../modules/secrets"
  
  project     = var.project
  environment              = var.environment
  tags                     = module.common.common_tags
  
  container_image = var.container_image
  secret_suffix = var.secret_suffix
  db_password = var.db_password
  mongodb_password = var.mongodb_password
}

# Security Module
module "security" {
  source = "../../modules/security"
  
  project     = var.project
  environment = var.environment
  name_prefix = "${var.project}-${var.environment}"
  tags        = var.tags
  
  vpc_id = module.vpc.vpc_id

  client_domain = var.client_domain
  admin_domain  = var.admin_domain

  db_username = var.db_username_arn != null ? var.db_username_arn : module.secrets.database_arn
  db_password_arn = var.db_password_arn != null ? var.db_password_arn : module.secrets.database_arn

  mongodb_username = var.mongodb_username_arn != null ? var.mongodb_username_arn : module.secrets.mongodb_arn
  mongodb_password_arn = var.mongodb_password_arn != null ? var.mongodb_password_arn : module.secrets.mongodb_arn

  sonar_token_arn = var.sonar_token_arn != null ? var.sonar_token_arn : module.secrets.sonar_token_arn

  certificate_arn = var.certificate_arn

  callback_urls = [
    "https://${var.client_domain}/callback",
    "https://${var.admin_domain}/callback"
  ]

  logout_urls = [
    "https://${var.client_domain}",
    "https://${var.admin_domain}"
  ]

  enable_encryption = true
  enable_backup     = true
  enable_monitoring = true
}

# Storage Module
module "storage" {
  project     = var.project
  source                = "../../modules/storage"
  name_prefix           = local.name_prefix
  environment           = var.environment
  vpc_id            = module.networking.vpc_id
  vpc_cidr_blocks   = [local.current_vpc_config.cidr_block]
  private_subnet_ids    = module.networking.private_subnet_ids
  kms_key_id        = module.security.kms_key_id
  db_instance_class     = local.env_config[var.environment].db_instance_class
  db_name               = var.db_name
  db_username           = var.db_username
  db_password           = var.db_password
  use_existing_cluster  = false
  mongodb_ami           = var.mongodb_ami
  mongodb_instance_type = local.env_config[var.environment].instance_type
  tags                  = module.common.common_tags
}

# Compute Module
module "compute" {
  source = "../../modules/compute"
  
  name_prefix = var.name_prefix
  project     = var.project
  environment = var.environment
  tags        = var.tags
  
  vpc_id = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids
  public_subnet_ids  = module.vpc.public_subnet_ids

  task_cpu    = 512
  task_memory = 1024
  container_port = var.container_port
  container_image_arn = module.secrets.container_image_arn
  certificate_arn = var.certificate_arn != null ? var.certificate_arn : module.security.certificate_arn
  rds_secret_arn = var.db_password_arn != null ? var.db_password_arn : module.secrets.database_arn
  mongodb_secret_arn = var.mongodb_password_arn != null ? var.mongodb_password_arn : module.secrets.mongodb_arn
}

# CICD Module
module "cicd" {
  source = "../../modules/cicd"
  
  name_prefix = var.name_prefix
  environment = var.environment
  tags        = var.tags
  
  client_repository_url = var.client_repository_arn != null ? var.client_repository_arn : module.secrets.client_repository_arn
  admin_repository_url = var.admin_repository_arn != null ? var.admin_repository_arn : module.secrets.admin_repository_arn
  source_token = module.secrets.source_token_arn
  api_url = module.compute.alb_dns_name
  cognito_domain = module.security.cognito_domain
  cognito_client_id = module.security.cognito_user_pool_client_id
  cognito_redirect_uri = "https://${var.client_domain}/callback"
  domain_name = "${var.environment}.finefinds.com"
}

# ALB Module
module "alb" {
  source = "../../modules/alb"

  project     = var.project
  environment = var.environment
  vpc_id      = module.vpc.vpc_id
  subnet_ids  = module.vpc.public_subnet_ids
  name        = "${var.project}-${var.environment}-alb"
  security_group_name = "${var.project}-${var.environment}-alb-sg"
  vpc_cidr_blocks = [var.vpc_cidr]
  container_port = var.container_port
  certificate_arn = var.certificate_arn != null ? var.certificate_arn : module.security.certificate_arn

  health_check_path     = "/health"
  health_check_port     = var.container_port
  health_check_interval = 30
  health_check_timeout  = 5
  health_check_healthy_threshold   = 2
  health_check_unhealthy_threshold = 3

  tags = var.tags
}

# ECR Module
module "ecr" {
  source = "../../modules/ecr"

  project     = var.project
  environment = var.environment
  tags        = module.common.common_tags
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

  tags = module.common.common_tags
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

  tags = module.common.common_tags
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

  tags = module.common.common_tags
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

  tags = module.common.common_tags
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

# Monitoring Module
module "monitoring" {
  source = "../../modules/monitoring"

  project     = var.project
  environment = var.environment
  name_prefix = local.name_prefix
  tags        = module.common.common_tags

  vpc_id             = module.networking.vpc_id
  private_subnet_ids = module.networking.private_subnet_ids
  public_subnet_ids  = module.networking.public_subnet_ids

  alb_arn            = module.alb.alb_arn
  alb_dns_name       = module.alb.alb_dns_name
  alb_arn_suffix     = module.alb.alb_arn_suffix
  ecs_cluster_arn    = module.compute.cluster_arn
  ecs_cluster_name   = module.compute.cluster_name
  ecs_service_arn    = module.compute.service_arn
  ecs_service_name   = module.compute.service_name
  rds_instance_id    = module.rds.db_instance_id
  rds_endpoint       = module.rds.db_instance_endpoint

  enable_cloudwatch  = true
  enable_xray        = true
  enable_cloudtrail  = true
  log_retention_days = 30
  alert_email        = var.alert_email
  aws_region         = var.aws_region
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
  sonar_token      = var.sonar_token
  graphql_endpoint = local.graphql_endpoint

  tags = module.common.common_tags
}

# Variables
variable "secret_suffix" {
  description = "Suffix for secret names"
  type        = string
  default     = "latest"
}

# Outputs
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

output "rds_endpoint" {
  description = "Endpoint of the RDS instance"
  value       = module.rds.db_instance_endpoint
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

module "networking" {
  source = "../../modules/networking"
  
  project     = var.project
  environment = var.environment
  name_prefix = local.name_prefix
  tags        = module.common.common_tags
  vpc_config  = local.current_vpc_config
}

module "database" {
  source = "../../modules/database"

  project     = var.project
  environment = var.environment
  name_prefix = local.name_prefix
  tags        = module.common.common_tags

  vpc_id              = module.networking.vpc_id
  private_subnet_ids  = module.networking.database_subnet_ids
  ecs_security_group_id = module.compute.ecs_security_group_id
  kms_key_id          = module.security.kms_key_id

  instance_class    = local.current_env_config.db_instance_class
  allocated_storage = 20
  db_name          = "finefindslk"
}