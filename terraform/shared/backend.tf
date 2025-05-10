terraform {
  backend "s3" {
    # These values will be filled in by the environment-specific configurations
    # bucket         = "finefinds-terraform-state-${var.environment}"
    # key            = "terraform.tfstate"
    # region         = "us-east-1"
    # dynamodb_table = "finefinds-terraform-locks"
    # encrypt        = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.0"
    }
  }
} 