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

# Local variables
locals {
  name_prefix = "finefinds-${var.environment}"
  certificate_arn = data.aws_acm_certificate.main.arn != null ? data.aws_acm_certificate.main.arn : "arn:aws:acm:us-east-1:${data.aws_caller_identity.current.account_id}:certificate/${var.environment}-finefinds-com"
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
  name_prefix = local.name_prefix
  tags        = var.tags

  vpc_id             = module.networking.vpc_id
  private_subnet_ids = module.networking.private_subnet_ids
  public_subnet_ids  = module.networking.public_subnet_ids

  alb_arn            = module.compute.alb_arn
  alb_dns_name       = module.compute.alb_dns_name
  ecs_cluster_arn    = module.compute.cluster_arn
  ecs_service_arn    = module.compute.service_arn
  rds_instance_id    = module.database.db_instance_id
  rds_endpoint       = module.database.db_endpoint

  enable_cloudwatch = var.monitoring_config.enable_cloudwatch
  enable_xray       = var.monitoring_config.enable_xray
  enable_cloudtrail = var.monitoring_config.enable_cloudtrail
  log_retention_days = var.monitoring_config.log_retention_days
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
  value       = module.networking.vpc_id
}

output "cluster_name" {
  description = "Name of the ECS cluster"
  value       = module.compute.cluster_name
}

output "service_name" {
  description = "Name of the ECS service"
  value       = module.compute.service_name
}

output "db_endpoint" {
  description = "Endpoint of the RDS instance"
  value       = module.database.db_endpoint
}

output "alb_dns_name" {
  description = "DNS name of the ALB"
  value       = module.compute.alb_dns_name
}

output "log_group_name" {
  description = "Name of the CloudWatch log group"
  value       = module.compute.log_group_name
}

# Networking Module
module "networking" {
  source = "../../modules/networking"

  project     = var.project
  environment = var.environment
  name_prefix = local.name_prefix
  tags        = var.tags

  vpc_config = var.vpc_config
}

# Database Module
module "database" {
  source = "../../modules/database"

  project     = var.project
  environment = var.environment
  name_prefix = local.name_prefix
  tags        = var.tags

  vpc_id             = module.networking.vpc_id
  private_subnet_ids = module.networking.private_subnet_ids
  ecs_security_group_id = module.ecs.security_group_id
  kms_key_id         = module.security.kms_key_id

  instance_class         = var.database_config.instance_class
  allocated_storage     = var.database_config.allocated_storage
  db_name              = var.database_config.db_name
  backup_retention_period = var.database_config.backup_retention_period
  multi_az             = var.database_config.multi_az
  skip_final_snapshot  = var.database_config.skip_final_snapshot
  deletion_protection  = var.database_config.deletion_protection
}

# Compute Module
module "compute" {
  source = "../../modules/compute"

  project     = var.project
  environment = var.environment
  name_prefix = local.name_prefix
  tags        = var.tags

  vpc_id             = module.networking.vpc_id
  private_subnet_ids = module.networking.private_subnet_ids
  public_subnet_ids  = module.networking.public_subnet_ids

  task_cpu    = var.compute_config.task_cpu
  task_memory = var.compute_config.task_memory

  service_desired_count = var.compute_config.service_desired_count
  container_image      = var.compute_config.container_image
  container_port       = var.compute_config.container_port

  certificate_arn    = var.certificate_arn
  rds_secret_arn     = module.database.rds_secret_arn
  mongodb_secret_arn = var.mongodb_secret_arn

  health_check_path               = var.compute_config.health_check_path
  health_check_interval          = var.compute_config.health_check_interval
  health_check_timeout           = var.compute_config.health_check_timeout
  health_check_healthy_threshold = var.compute_config.health_check_healthy_threshold
  health_check_unhealthy_threshold = var.compute_config.health_check_unhealthy_threshold
}

# Security Module
module "security" {
  source = "../../modules/security"

  project     = var.project
  environment = var.environment
  name_prefix = local.name_prefix
  tags        = var.tags

  enable_encryption = var.security_config.enable_encryption
  enable_backup     = var.security_config.enable_backup
  enable_monitoring = var.security_config.enable_monitoring
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