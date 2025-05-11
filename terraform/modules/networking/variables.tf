variable "project" {
  description = "Project name"
  type        = string
  default     = "finefindslk"
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "tags" {
  description = "Additional tags for resources"
  type        = map(string)
  default     = {}
}

variable "vpc_config" {
  description = "VPC configuration"
  type = object({
    cidr_block           = string
    availability_zones   = list(string)
    public_subnets      = list(string)
    private_subnets     = list(string)
    database_subnets    = list(string)
    enable_nat_gateway  = bool
    single_nat_gateway  = bool
    enable_vpn_gateway  = bool
    enable_flow_log     = bool
    flow_log_retention  = number
  })
  default = {
    cidr_block           = "10.0.0.0/16"
    availability_zones   = ["us-east-1a", "us-east-1b", "us-east-1c"]
    public_subnets      = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
    private_subnets     = ["10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24"]
    database_subnets    = ["10.0.21.0/24", "10.0.22.0/24", "10.0.23.0/24"]
    enable_nat_gateway  = true
    single_nat_gateway  = false
    enable_vpn_gateway  = false
    enable_flow_log     = true
    flow_log_retention  = 30
  }
} 