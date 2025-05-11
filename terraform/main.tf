module "compute" {
  source = "./modules/compute"

  environment = var.environment
  vpc_id      = module.networking.vpc_id
  subnet_ids  = module.networking.private_subnet_ids
}

module "security" {
  source = "./modules/security"

  environment      = var.environment
  domain_name      = var.domain_name
  certificate_arn  = var.certificate_arn
}

module "storage" {
  source = "./modules/storage"

  environment = var.environment
  buckets     = var.buckets
}

module "amplify" {
  source = "./modules/amplify"

  environment   = var.environment
  app_name      = var.app_name
  github_token  = var.github_token
  domain_name   = var.domain_name
}

module "monitoring" {
  source = "./modules/monitoring"

  environment = var.environment
  vpc_id      = module.networking.vpc_id
} 