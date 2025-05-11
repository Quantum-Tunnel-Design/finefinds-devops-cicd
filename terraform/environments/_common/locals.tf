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
      min_size         = 1
      max_size         = 2
      task_cpu         = 256
      task_memory      = 512
      service_count    = 1
    }
    qa = {
      instance_type     = "t3.small"
      db_instance_class = "db.t3.small"
      min_size         = 2
      max_size         = 4
      task_cpu         = 512
      task_memory      = 1024
      service_count    = 2
    }
    staging = {
      instance_type     = "t3.medium"
      db_instance_class = "db.t3.medium"
      min_size         = 2
      max_size         = 4
      task_cpu         = 1024
      task_memory      = 2048
      service_count    = 2
    }
    prod = {
      instance_type     = "t3.large"
      db_instance_class = "db.t3.large"
      min_size         = 3
      max_size         = 6
      task_cpu         = 2048
      task_memory      = 4096
      service_count    = 3
    }
  }

  # VPC configurations
  vpc_config = {
    dev = {
      cidr             = "10.1.0.0/16"
      public_subnets   = ["10.1.101.0/24", "10.1.102.0/24"]
      private_subnets  = ["10.1.1.0/24", "10.1.2.0/24"]
    }
    qa = {
      cidr             = "10.2.0.0/16"
      public_subnets   = ["10.2.101.0/24", "10.2.102.0/24"]
      private_subnets  = ["10.2.1.0/24", "10.2.2.0/24"]
    }
    staging = {
      cidr             = "10.3.0.0/16"
      public_subnets   = ["10.3.101.0/24", "10.3.102.0/24"]
      private_subnets  = ["10.3.1.0/24", "10.3.2.0/24"]
    }
    prod = {
      cidr             = "10.4.0.0/16"
      public_subnets   = ["10.4.101.0/24", "10.4.102.0/24"]
      private_subnets  = ["10.4.1.0/24", "10.4.2.0/24"]
    }
  }
} 