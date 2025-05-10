provider "aws" {
  region = var.aws_region
  
  # Use different profiles for different accounts
  profile = var.environment == "prod" ? "prod" : "nonprod"
  
  # Assume role for cross-account access if needed
  assume_role {
    role_arn = var.environment == "prod" 
      ? "arn:aws:iam::${var.prod_account_id}:role/TerraformExecutionRole"
      : "arn:aws:iam::${var.nonprod_account_id}:role/TerraformExecutionRole"
  }

  default_tags {
    tags = {
      Environment = var.environment
      Project     = var.project
      ManagedBy   = "terraform"
    }
  }
}

# Kubernetes provider configuration
provider "kubernetes" {
  config_path = "~/.kube/config"
}

# Helm provider configuration
provider "helm" {
  kubernetes {
    config_path = "~/.kube/config"
  }
} 