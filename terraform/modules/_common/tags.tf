locals {
  # Base tags that should be present on all resources
  base_tags = {
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "Terraform"
    Service     = "FineFinds"
  }

  # Common tags that can be extended by modules
  common_tags = merge(
    local.base_tags,
    var.tags,
    {
      Terraform = "true"
    }
  )
} 