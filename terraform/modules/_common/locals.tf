locals {
  # Common name prefix for all resources
  name_prefix = "${var.project}-${var.environment}"

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
    qa = {
      instance_type     = "t3.small"
      db_instance_class = "db.t3.small"
      min_size         = 2
      max_size         = 4
      task_cpu         = 512
      task_memory      = 1024
      service_count    = 2
      backup_retention = 3
      multi_az        = false
    }
    staging = {
      instance_type     = "t3.medium"
      db_instance_class = "db.t3.medium"
      min_size         = 2
      max_size         = 4
      task_cpu         = 1024
      task_memory      = 2048
      service_count    = 2
      backup_retention = 5
      multi_az        = true
    }
    prod = {
      instance_type     = "t3.large"
      db_instance_class = "db.t3.large"
      min_size         = 3
      max_size         = 6
      task_cpu         = 2048
      task_memory      = 4096
      service_count    = 3
      backup_retention = 7
      multi_az        = true
    }
  }

  # Get current environment configuration
  current_env_config = local.env_config[var.environment]

  # VPC configurations
  vpc_config = {
    dev = {
      cidr             = "10.1.0.0/16"
      public_subnets   = ["10.1.101.0/24", "10.1.102.0/24"]
      private_subnets  = ["10.1.1.0/24", "10.1.2.0/24"]
      database_subnets = ["10.1.11.0/24", "10.1.12.0/24"]
    }
    qa = {
      cidr             = "10.2.0.0/16"
      public_subnets   = ["10.2.101.0/24", "10.2.102.0/24"]
      private_subnets  = ["10.2.1.0/24", "10.2.2.0/24"]
      database_subnets = ["10.2.11.0/24", "10.2.12.0/24"]
    }
    staging = {
      cidr             = "10.3.0.0/16"
      public_subnets   = ["10.3.101.0/24", "10.3.102.0/24"]
      private_subnets  = ["10.3.1.0/24", "10.3.2.0/24"]
      database_subnets = ["10.3.11.0/24", "10.3.12.0/24"]
    }
    prod = {
      cidr             = "10.4.0.0/16"
      public_subnets   = ["10.4.101.0/24", "10.4.102.0/24"]
      private_subnets  = ["10.4.1.0/24", "10.4.2.0/24"]
      database_subnets = ["10.4.11.0/24", "10.4.12.0/24"]
    }
  }

  # Get current VPC configuration
  current_vpc_config = local.vpc_config[var.environment]

  # Infrastructure-dependent locals
  has_vpc = var.vpc_id != null
  has_private_subnets = length(var.private_subnet_ids) > 0
  has_public_subnets = length(var.public_subnet_ids) > 0
} 