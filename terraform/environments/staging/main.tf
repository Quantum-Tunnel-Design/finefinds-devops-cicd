provider "aws" {
  region = var.aws_region
}

# Get current AWS account ID
data "aws_caller_identity" "current" {}

# Check if certificate exists
data "aws_acm_certificate" "main" {
  domain      = "${var.environment}.finefinds.lk"
  statuses    = ["ISSUED", "PENDING_VALIDATION"]
  most_recent = true
}

# Local variables
locals {
  certificate_arn = data.aws_acm_certificate.main.arn != null ? data.aws_acm_certificate.main.arn : "arn:aws:acm:us-east-1:${data.aws_caller_identity.current.account_id}:certificate/${var.environment}-finefindslk-com"
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

# Database Module
module "database" {
  source = "../../modules/database"

  project     = var.project
  environment = var.environment
  name_prefix = local.name_prefix
  tags        = var.tags

  vpc_id             = module.networking.vpc_id
  private_subnet_ids = module.networking.private_subnet_ids
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

  certificate_arn    = local.certificate_arn
  rds_secret_arn     = module.database.rds_secret_arn
  mongodb_secret_arn = var.mongodb_secret_arn

  health_check_path               = var.compute_config.health_check_path
  health_check_interval          = var.compute_config.health_check_interval
  health_check_timeout           = var.compute_config.health_check_timeout
  health_check_healthy_threshold = var.compute_config.health_check_healthy_threshold
  health_check_unhealthy_threshold = var.compute_config.health_check_unhealthy_threshold
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

# Update database security group after compute is created
resource "aws_security_group_rule" "database_from_compute" {
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  source_security_group_id = module.compute.tasks_security_group_id
  security_group_id        = module.database.db_security_group_id
} 