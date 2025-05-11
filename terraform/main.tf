provider "aws" {
  region = var.aws_region
}

locals {
  name_prefix = "finefinds-${var.environment}"
  tags = merge(
    var.tags,
    {
      Environment = var.environment
      Project     = var.project
      ManagedBy   = "terraform"
    }
  )
}

# VPC Module
module "vpc" {
  source = "./modules/vpc"

  project     = var.project
  environment = var.environment
  name_prefix = local.name_prefix
  tags        = local.tags
}

# Database Module
module "database" {
  source = "./modules/database"

  project     = var.project
  environment = var.environment
  name_prefix = local.name_prefix
  tags        = local.tags

  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids
  ecs_security_group_id = module.compute.ecs_security_group_id
  kms_key_id         = module.security.kms_key_id
}

# Compute Module
module "compute" {
  source = "./modules/compute"

  project     = var.project
  environment = var.environment
  name_prefix = local.name_prefix
  tags        = local.tags

  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids
  public_subnet_ids  = module.vpc.public_subnet_ids

  task_cpu    = var.task_cpu
  task_memory = var.task_memory

  service_desired_count = var.service_desired_count
  container_image      = var.container_image
  container_port       = var.container_port

  certificate_arn    = var.certificate_arn
  rds_secret_arn     = module.database.rds_secret_arn
  mongodb_secret_arn = var.mongodb_secret_arn

  health_check_path               = var.health_check_path
  health_check_interval          = var.health_check_interval
  health_check_timeout           = var.health_check_timeout
  health_check_healthy_threshold = var.health_check_healthy_threshold
  health_check_unhealthy_threshold = var.health_check_unhealthy_threshold
}

# Security Module
module "security" {
  source = "./modules/security"

  project     = var.project
  environment = var.environment
  name_prefix = local.name_prefix
  tags        = local.tags
}

# Monitoring Module
module "monitoring" {
  source = "./modules/monitoring"

  project     = var.project
  environment = var.environment
  name_prefix = local.name_prefix
  tags        = local.tags

  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids
  public_subnet_ids  = module.vpc.public_subnet_ids

  alb_arn            = module.compute.alb_arn
  alb_dns_name       = module.compute.alb_dns_name
  ecs_cluster_arn    = module.compute.ecs_cluster_arn
  ecs_service_arn    = module.compute.ecs_service_arn
  rds_instance_id    = module.database.db_instance_id
  rds_endpoint       = module.database.db_endpoint
} 