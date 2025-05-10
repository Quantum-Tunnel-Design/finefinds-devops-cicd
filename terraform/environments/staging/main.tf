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
  name_prefix = "${var.project}-${var.environment}"
  common_tags = {
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

# VPC Module
module "vpc" {
  source = "../../modules/vpc"

  project     = var.project
  environment = var.environment

  # Staging uses moderate resources
  vpc_cidr             = "10.3.0.0/16"
  availability_zones   = ["${var.aws_region}a", "${var.aws_region}b"]
  private_subnet_cidrs = ["10.3.1.0/24", "10.3.2.0/24"]
  public_subnet_cidrs  = ["10.3.101.0/24", "10.3.102.0/24"]
  tags                 = local.common_tags
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
  database_url_arn  = module.rds.db_password_arn
  mongodb_uri_arn   = module.mongodb.mongodb_password_arn
  aws_region        = var.aws_region
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
  skip_final_snapshot = true
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

# Secrets Module
module "secrets" {
  source = "../../modules/secrets"

  project     = var.project
  environment = var.environment
  secret_suffix = var.secret_suffix
  use_existing_secrets = false
  tags = local.common_tags
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
  db_instance_class = "db.t3.micro"
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
  source_token = var.source_token
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

module "networking" {
  source              = "../../modules/networking"
  name_prefix         = local.name_prefix
  vpc_cidr            = var.vpc_cidr
  availability_zones  = var.availability_zones
  tags                = local.common_tags
}

# Update security module to use local.certificate_arn
module "security" {
  source            = "../../modules/security"
  name_prefix       = "${var.project}-${var.environment}"
  tags              = local.common_tags
  callback_urls     = ["https://${var.environment}.finefinds.com/callback"]
  logout_urls       = ["https://${var.environment}.finefinds.com/logout"]
  certificate_arn   = local.certificate_arn
  db_username       = var.db_username
  db_password       = var.db_password
  mongodb_username  = var.mongodb_username
  mongodb_password  = var.mongodb_password
  sonar_token       = var.sonar_token
  depends_on        = [module.secrets]
}

module "storage" {
  source                = "../../modules/storage"
  name_prefix           = "${var.project}-${var.environment}"
  environment           = var.environment
  vpc_id                = module.vpc.vpc_id
  private_subnet_ids    = module.vpc.private_subnet_ids
  ecs_security_group_id = module.compute.ecs_security_group_id
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

module "compute" {
  source                   = "../../modules/compute"
  name_prefix              = "${var.project}-${var.environment}"
  environment              = var.environment
  aws_region               = var.aws_region
  vpc_id                   = module.vpc.vpc_id
  public_subnet_ids        = module.vpc.public_subnet_ids
  private_subnet_ids       = module.vpc.private_subnet_ids
  certificate_arn          = var.certificate_arn
  task_cpu                 = 512
  task_memory              = 1024
  task_execution_role_arn  = module.security.ecs_task_execution_role_arn
  task_role_arn            = module.security.ecs_task_role_arn
  container_image          = module.cicd.ecr_repository_url
  container_port           = var.container_port
  container_environment    = []
  service_desired_count    = 2
  rds_secret_arn           = module.security.rds_secret_arn
  mongodb_secret_arn       = module.security.mongodb_secret_arn
  tags                     = local.common_tags
  depends_on               = [module.vpc, module.security, module.storage]
}

module "cicd" {
  source            = "../../modules/cicd"
  name_prefix       = "${var.project}-${var.environment}"
  environment       = var.environment
  repository_url    = var.repository_url
  source_token      = var.source_token
  api_url           = module.compute.alb_dns_name
  cognito_domain    = module.security.cognito_domain
  cognito_client_id = module.security.cognito_user_pool_client_id
  cognito_redirect_uri = "https://${var.environment}.finefinds.com/callback"
  domain_name       = "${var.environment}.finefinds.com"
  tags              = local.common_tags
  depends_on        = [module.compute]
}

# Variables
variable "secret_suffix" {
  description = "Suffix for secret names"
  type        = string
  default     = formatdate("YYYYMMDDHHmmss", timestamp())
}

variable "certificate_arn" {
  description = "ARN of the SSL certificate for the ALB"
  type        = string
  default     = null
} 