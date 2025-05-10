locals {
  # Common tags
  common_tags = {
    Environment = var.environment
    Project     = var.project
    Terraform   = "true"
    ManagedBy   = "terraform"
  }

  # VPC Configuration
  vpc_cidr = "10.0.0.0/16"
  azs      = ["us-east-1a", "us-east-1b"]

  # Subnet CIDRs
  public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnet_cidrs = ["10.0.3.0/24", "10.0.4.0/24"]

  # Security Group Names
  alb_sg_name        = "${var.project}-${var.environment}-alb-sg"
  ecs_sg_name        = "${var.project}-${var.environment}-ecs-sg"
  rds_sg_name        = "${var.project}-${var.environment}-rds-sg"
  mongodb_sg_name    = "${var.project}-${var.environment}-mongodb-sg"
  sonarqube_sg_name  = "${var.project}-${var.environment}-sonarqube-sg"

  # Resource Names
  alb_name           = "${var.project}-${var.environment}-alb"
  ecs_cluster_name   = "${var.project}-${var.environment}-ecs"
  rds_name           = "${var.project}-${var.environment}-rds"
  mongodb_name       = "${var.project}-${var.environment}-mongodb"
  sonarqube_name     = "${var.project}-${var.environment}-sonarqube"

  # Secret Names with timestamp suffix
  db_password_secret_name     = "${var.project}/${var.environment}/db-password-${var.secret_suffix}"
  mongodb_password_secret_name = "${var.project}/${var.environment}/mongodb-password-${var.secret_suffix}"
  sonarqube_password_secret_name = "${var.project}/${var.environment}/sonarqube-password-${var.secret_suffix}"

  # Database Configuration
  db_username = "admin"
  db_name     = "finefinds"
  db_port     = 5432

  # Container Configuration
  container_port = 3000
  task_cpu       = 256
  task_memory    = 512

  # Health Check Configuration
  health_check_path     = "/health"
  health_check_port     = "traffic-port"
  health_check_interval = 30
  health_check_timeout  = 5
  health_check_healthy_threshold   = 2
  health_check_unhealthy_threshold = 2

  # SonarQube Configuration
  sonarqube_port = 9000
  sonarqube_path = "/"

  # MongoDB Configuration
  mongodb_port = 27017
} 