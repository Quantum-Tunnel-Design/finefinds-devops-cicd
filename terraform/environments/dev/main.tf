provider "aws" {
  region = var.aws_region
}

# Get current AWS account ID
data "aws_caller_identity" "current" {}

# Use common module for standard variables
module "common" {
  source = "../../modules/_common"

  project     = var.project
  environment = var.environment
  aws_region  = var.aws_region
  vpc_id      = module.networking.vpc_id
  private_subnet_ids = module.networking.private_subnet_ids
  public_subnet_ids  = module.networking.public_subnet_ids
  tags        = var.tags
}

module "backend" {
  source        = "../../modules/backend"
  name_prefix   = "${var.project}-${var.environment}-api"
  environment   = var.environment
  project       = var.project
  vpc_id        = module.networking.vpc_id
  private_subnet_ids = module.networking.private_subnet_ids
  subnet_ids = module.networking.private_subnet_ids
  alb_target_group_arn = module.alb.target_group_arn

  container_definitions = jsonencode([
    {
      name      = "api"
      image     = "${module.secrets.container_image_arn}"
      essential = true
      portMappings = [
        {
          containerPort = 4000
          protocol      = "tcp"
        }
      ]
      environment = [
        { name = "NODE_ENV", value = var.environment },
        { name = "PORT", value = "4000" }
      ]
      secrets = [
        {
          name      = "DB_PASSWORD"
          valueFrom = module.secrets.database_arn
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = "/ecs/${var.project}-${var.environment}-api"
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = "api"
        }
      }
    }
  ])

  cpu                        = 512
  memory                     = 1024
  desired_count              = 2
  min_capacity               = 2
  max_capacity               = 5
  assign_public_ip           = false
  ecs_task_execution_role_arn = module.security.ecs_task_execution_role_arn
  ecs_task_role_arn           = module.security.ecs_task_role_arn

  tags = var.tags

  rds_secret_arn         = module.secrets.database_arn
  certificate_arn        = var.certificate_arn != null ? var.certificate_arn : module.security.certificate_arn
  container_image_arn    = module.secrets.container_image_arn
  alb_security_group_id  = module.alb.security_group_id
  public_subnet_ids      = module.networking.public_subnet_ids
}

# Secrets Module
module "secrets" {
  source = "../../modules/secrets"
  
  project     = var.project
  environment              = var.environment
  tags                     = module.common.common_tags
}

# Security Module
module "security" {
  source = "../../modules/security"
  
  project     = var.project
  environment = var.environment
  name_prefix = "${var.project}-${var.environment}"
  tags        = var.tags
  
  vpc_id = module.networking.vpc_id

  client_domain = var.client_domain
  admin_domain  = var.admin_domain

  db_password_arn = var.db_password_arn != null ? var.db_password_arn : module.secrets.database_arn
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
  tags                  = module.common.common_tags
}

# CICD Module
module "amplify" {
  source = "../../modules/amplify"
  
  name_prefix = var.name_prefix
  environment = var.environment
  tags        = var.tags
  
  client_repository_url = var.client_repository_arn != null ? var.client_repository_arn : module.secrets.client_repository_arn
  admin_repository_url = var.admin_repository_arn != null ? var.admin_repository_arn : module.secrets.admin_repository_arn
  source_token = module.secrets.source_token_arn
  api_url = module.alb.alb_dns_name
  cognito_domain = module.cognito.client_pool_domain
  cognito_client_id = module.cognito.client_app_client_id
  cognito_redirect_uri = "https://${var.client_domain}/callback"
  domain_name = "${var.environment}.finefinds.lk"
}

# ALB Module
module "alb" {
  source = "../../modules/alb"

  project     = var.project
  environment = var.environment
  vpc_id      = module.networking.vpc_id
  subnet_ids  = module.networking.public_subnet_ids
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
  name_prefix = local.name_prefix

  project     = var.project
  environment = var.environment
  tags        = module.common.common_tags
}

# RDS Module
module "rds" {
  source = "../../modules/rds"

  project     = var.project
  environment = var.environment
  vpc_id      = module.networking.vpc_id
  subnet_ids  = module.networking.database_subnet_ids
  name        = local.rds_name
  security_group_name = local.rds_sg_name
  vpc_cidr_blocks = [local.vpc_cidr]

  db_username = local.db_username
  db_name     = local.db_name
  db_password_arn = module.secrets.database_arn

  tags = module.common.common_tags
}

# Cognito Module - No VPC dependencies
module "cognito" {
  source = "../../modules/cognito"

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
  ecs_cluster_arn    = module.backend.cluster_arn
  ecs_cluster_name   = module.backend.cluster_name
  ecs_service_arn    = module.backend.service_arn
  ecs_service_name   = module.backend.service_name
  rds_instance_id    = module.rds.db_instance_id
  rds_endpoint       = module.rds.db_instance_endpoint

  enable_cloudwatch  = true
  enable_xray        = true
  enable_cloudtrail  = true
  log_retention_days = 30
  alert_email        = var.alert_email
  aws_region         = var.aws_region
}

# Variables
variable "secret_suffix" {
  description = "Suffix for secret names"
  type        = string
  default     = "latest"
}

# Outputs
output "rds_security_group_id" {
  description = "ID of the RDS security group"
  value       = module.rds.security_group_id
}

output "rds_endpoint" {
  description = "Endpoint of the RDS instance"
  value       = module.rds.db_instance_endpoint
}

output "cognito_client_id" {
  description = "ID of the Cognito User Pool Client (Client App)"
  value       = module.cognito.client_app_client_id
}

output "s3_bucket_name" {
  description = "Name of the S3 bucket (specifically the uploads bucket)"
  value       =  module.storage.bucket_names["uploads"]
}

module "networking" {
  source = "../../modules/networking"
  
  project     = var.project
  environment = var.environment
  name_prefix = local.name_prefix
  tags        = module.common.common_tags
  vpc_config  = local.current_vpc_config
}