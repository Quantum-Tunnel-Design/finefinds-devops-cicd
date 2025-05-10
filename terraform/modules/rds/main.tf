# RDS Subnet Group
resource "aws_db_subnet_group" "main" {
  name       = "${var.project}-${var.environment}-db-subnet-group"
  subnet_ids = var.subnet_ids

  tags = {
    Environment = var.environment
    Project     = var.project
    Terraform   = "true"
  }
}

# RDS Security Group
resource "aws_security_group" "rds" {
  name        = "${var.project}-${var.environment}-rds-sg"
  description = "Allow inbound traffic for RDS"
  vpc_id      = var.vpc_id

  ingress {
    protocol        = "tcp"
    from_port       = 5432
    to_port         = 5432
    security_groups = [var.ecs_security_group_id]
  }

  tags = {
    Environment = var.environment
    Project     = var.project
    Terraform   = "true"
  }
}

# Generate random password for RDS
resource "random_password" "db_password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

# Store the password in Secrets Manager
resource "aws_secretsmanager_secret" "db_password" {
  name = "${var.project}-${var.environment}-db-password"
  description = "Database password for ${var.environment} environment"
}

resource "aws_secretsmanager_secret_version" "db_password" {
  secret_id     = aws_secretsmanager_secret.db_password.id
  secret_string = random_password.db_password.result
}

# RDS Instance
resource "aws_db_instance" "main" {
  identifier = "${var.project}-${var.environment}-db"

  engine         = "postgres"
  engine_version = "14.7"
  instance_class = var.instance_class

  allocated_storage     = var.allocated_storage
  storage_type         = "gp2"
  storage_encrypted    = true

  db_name  = "finefinds"
  username = var.db_username
  password = random_password.db_password.result

  vpc_security_group_ids = [aws_security_group.rds.id]
  db_subnet_group_name   = aws_db_subnet_group.main.name

  backup_retention_period = 7
  skip_final_snapshot    = var.skip_final_snapshot

  tags = {
    Environment = var.environment
    Project     = var.project
    Terraform   = "true"
  }
}

# Variables
variable "project" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where resources will be created"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for the RDS instance"
  type        = list(string)
}

variable "ecs_security_group_id" {
  description = "Security group ID of the ECS tasks"
  type        = string
}

variable "db_username" {
  description = "Master username for RDS"
  type        = string
  default     = "admin"
}

variable "instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "allocated_storage" {
  description = "Allocated storage in GB"
  type        = number
  default     = 20
}

variable "skip_final_snapshot" {
  description = "Skip final snapshot when destroying"
  type        = bool
  default     = false
}

# Outputs
output "db_instance_id" {
  description = "ID of the RDS instance"
  value       = aws_db_instance.main.id
}

output "db_instance_endpoint" {
  description = "Endpoint of the RDS instance"
  value       = aws_db_instance.main.endpoint
}

output "db_instance_identifier" {
  description = "Name of the RDS instance"
  value       = aws_db_instance.main.identifier
}

output "db_instance_port" {
  description = "Port of the RDS instance"
  value       = aws_db_instance.main.port
}

output "db_password_arn" {
  description = "ARN of the database password in Secrets Manager"
  value       = aws_secretsmanager_secret.db_password.arn
  sensitive   = true
}

output "db_subnet_group_name" {
  description = "Name of the DB subnet group"
  value       = aws_db_subnet_group.main.name
} 