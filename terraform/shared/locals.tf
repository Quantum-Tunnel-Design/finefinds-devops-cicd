locals {
  # Common tags for all resources
  common_tags = {
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "Terraform"
    Service     = "FineFinds"
  }

  # Environment-specific configurations
  environment_config = {
    sandbox = {
      instance_type = "t3.micro"
      db_instance_class = "db.t3.micro"
      min_capacity = 1
      max_capacity = 2
    }
    dev = {
      instance_type = "t3.small"
      db_instance_class = "db.t3.small"
      min_capacity = 1
      max_capacity = 2
    }
    qa = {
      instance_type = "t3.medium"
      db_instance_class = "db.t3.medium"
      min_capacity = 2
      max_capacity = 4
    }
    staging = {
      instance_type = "t3.large"
      db_instance_class = "db.t3.large"
      min_capacity = 2
      max_capacity = 4
    }
    prod = {
      instance_type = "t3.xlarge"
      db_instance_class = "db.t3.xlarge"
      min_capacity = 2
      max_capacity = 8
    }
  }

  # Get current environment configuration
  env_config = local.environment_config[var.environment]

  # Common naming convention
  name_prefix = "${var.project}-${var.environment}"
} 