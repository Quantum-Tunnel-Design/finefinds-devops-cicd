locals {
  # Common tags for all resources
  common_tags = {
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "Terraform"
    Service     = "FineFinds"
    Terraform   = "true"
  }
} 