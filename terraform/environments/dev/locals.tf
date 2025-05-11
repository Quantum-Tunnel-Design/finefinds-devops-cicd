locals {
  name_prefix = "${var.project}-${var.environment}"

  common_tags = {
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "Terraform"
    Service     = "FineFinds"
  }

  # Domain and Endpoint Configurations (for Amplify, Cognito callbacks, etc.)
  client_domain    = "${var.project}-client-${var.environment}.amplifyapp.com"
  admin_domain     = "${var.project}-admin-${var.environment}.amplifyapp.com"
  graphql_endpoint = "https://${local.client_domain}/graphql"

  # Environment-specific configurations
  env_config = {
    dev = {
      instance_type     = "t3.micro"
      db_instance_class = "db.t3.micro"
      min_size         = 1
      max_size         = 2
      task_cpu         = 256
      task_memory      = 512
      service_count    = 1
      backup_retention = 1
      multi_az        = false
    }
  }

  current_env_config = local.env_config[var.environment]

  # VPC configurations
  vpc_config = {
    dev = {
      cidr_block           = "10.1.0.0/16"
      availability_zones   = ["${var.aws_region}a", "${var.aws_region}b"]
      public_subnets      = ["10.1.101.0/24", "10.1.102.0/24"]
      private_subnets     = ["10.1.1.0/24", "10.1.2.0/24"]
      database_subnets    = ["10.1.201.0/24", "10.1.202.0/24"]
      enable_nat_gateway  = true
      single_nat_gateway  = true
      enable_vpn_gateway  = false
      enable_flow_log     = true
      flow_log_retention  = 30
    }
  }

  current_vpc_config = local.vpc_config[var.environment]

  # VPC Configuration for other modules if they need the primary CIDR directly
  vpc_cidr = local.current_vpc_config.cidr_block # Aligned with current_vpc_config
  # azs, public_subnet_cidrs, private_subnet_cidrs below are not directly used by modules anymore if they take IDs from module.networking
  # Keeping them for reference or other uses if any, but ensure they don't conflict.
  azs      = local.current_vpc_config.availability_zones # Aligned

  # Subnet CIDRs - These are illustrative if needed, but modules now use subnet IDs from module.networking
  public_subnet_cidrs  = local.current_vpc_config.public_subnets # Aligned
  private_subnet_cidrs = local.current_vpc_config.private_subnets # Aligned

  # Security Group Names
  alb_sg_name        = "${var.project}-${var.environment}-alb-sg"
  ecs_sg_name        = "${var.project}-${var.environment}-ecs-sg"
  rds_sg_name        = "${var.project}-${var.environment}-rds-sg"

  # Resource Names
  alb_name           = "${var.project}-${var.environment}-alb"
  ecs_cluster_name   = "${var.project}-${var.environment}-ecs"
  rds_name           = "${var.project}-${var.environment}-rds"

  # Database Configuration
  db_username = "admin"
  db_name     = "finefindslk"
  db_port     = 5432

  # Container Configuration
  container_port = 3000

  # Health Check Configuration
  health_check_path     = "/health"
  health_check_port     = "traffic-port"
  health_check_interval = 30
  health_check_timeout  = 5
  health_check_healthy_threshold   = 2
  health_check_unhealthy_threshold = 2

  # SonarQube Configuration
  task_cpu       = 512
  task_memory    = 1024
} 