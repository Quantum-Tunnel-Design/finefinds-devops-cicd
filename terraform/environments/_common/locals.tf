locals {
  # Common tags for all resources
  common_tags = {
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "Terraform"
    Service     = "FineFinds"
    Terraform   = "true"
  }

  # Common name prefix
  name_prefix = "${var.project}-${var.environment}"

  # Environment-specific configurations
  env_config = {
    dev = {
      instance_type     = "t3.micro"
      db_instance_class = "db.t3.micro"
    }
    qa = {
      instance_type     = "t3.small"
      db_instance_class = "db.t3.small"
    }
    staging = {
      instance_type     = "t3.medium"
      db_instance_class = "db.t3.medium"
    }
    prod = {
      instance_type     = "t3.large"
      db_instance_class = "db.t3.large"
    }
  }
} 