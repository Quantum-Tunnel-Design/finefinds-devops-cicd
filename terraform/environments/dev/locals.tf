locals {
  # VPC and Network
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids
  public_subnet_ids  = module.vpc.public_subnet_ids
  vpc_cidr          = "10.0.0.0/16"
  
  # Shared security group CIDR blocks
  vpc_cidr_blocks = ["10.0.0.0/8"]
  
  # Shared subnet group names
  db_subnet_group_name = "${var.project}-${var.environment}-db-subnet-group"
  
  # Shared tags
  common_tags = {
    Environment = var.environment
    Project     = var.project
    Terraform   = "true"
  }

  # Security group names
  alb_sg_name = "${var.project}-${var.environment}-alb-sg"
  ecs_sg_name = "${var.project}-${var.environment}-ecs-sg"
  rds_sg_name = "${var.project}-${var.environment}-rds-sg"
  mongo_sg_name = "${var.project}-${var.environment}-mongo-sg"
  sonarqube_sg_name = "${var.project}-${var.environment}-sonarqube-sg"

  # Resource names
  alb_name = "${var.project}-${var.environment}-alb"
  ecs_cluster_name = "${var.project}-${var.environment}"
  rds_name = "${var.project}-${var.environment}-db"
  mongodb_name = "${var.project}-${var.environment}-mongo"
  sonarqube_name = "${var.project}-${var.environment}-sonarqube"
} 