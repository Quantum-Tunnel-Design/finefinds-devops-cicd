# Data source for existing RDS instance
data "aws_db_instance" "existing" {
  count = var.use_existing_instance ? 1 : 0
  db_instance_identifier = "${var.project}-${var.environment}-db"
}

# Data source for existing subnet group
data "aws_db_subnet_group" "existing" {
  count = var.use_existing_subnet_group ? 1 : 0
  name  = "${var.project}-${var.environment}-db-subnet-group"
}

# RDS Subnet Group
resource "aws_db_subnet_group" "main" {
  count      = var.use_existing_subnet_group ? 0 : 1
  name       = "${var.project}-${var.environment}-db-subnet-group"
  subnet_ids = var.subnet_ids

  tags = {
    Environment = var.environment
    Project     = var.project
    Terraform   = "true"
  }

  lifecycle {
    ignore_changes = [name]
    prevent_destroy = true
  }
}

# RDS Security Group
resource "aws_security_group" "rds" {
  count       = var.use_existing_instance ? 0 : 1
  name        = "${var.project}-${var.environment}-rds-sg"
  description = "Allow inbound traffic for RDS"
  vpc_id      = var.vpc_id

  ingress {
    protocol    = "tcp"
    from_port   = 5432
    to_port     = 5432
    cidr_blocks = ["10.0.0.0/8"]  # Allow from VPC CIDR
  }

  tags = {
    Environment = var.environment
    Project     = var.project
    Terraform   = "true"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Use existing or new subnet group
locals {
  subnet_group_name = var.use_existing_subnet_group ? data.aws_db_subnet_group.existing[0].name : aws_db_subnet_group.main[0].name
  security_group_id = var.use_existing_instance ? var.existing_security_group_id : aws_security_group.rds[0].id
}

# RDS Instance
resource "aws_db_instance" "main" {
  count = var.use_existing_instance ? 0 : 1
  identifier = "${var.project}-${var.environment}-db"

  engine         = "postgres"
  engine_version = "17.5"
  instance_class = var.db_instance_class

  allocated_storage     = var.allocated_storage
  storage_type         = "gp2"
  storage_encrypted    = true

  db_name  = var.db_name
  username = "finefinds_admin"
  password = var.db_password

  vpc_security_group_ids = [local.security_group_id]
  db_subnet_group_name   = local.subnet_group_name

  backup_retention_period = 7
  skip_final_snapshot    = var.skip_final_snapshot

  tags = {
    Environment = var.environment
    Project     = var.project
    Terraform   = "true"
  }

  lifecycle {
    ignore_changes = [
      identifier,
      engine_version,
      password,
      db_name,
      username,
      allocated_storage,
      instance_class
    ]
    prevent_destroy = true
  }
}

# Use existing or new instance
locals {
  db_instance_id       = var.use_existing_instance ? data.aws_db_instance.existing[0].id : aws_db_instance.main[0].id
  db_instance_endpoint = var.use_existing_instance ? data.aws_db_instance.existing[0].endpoint : aws_db_instance.main[0].endpoint
  db_instance_port     = var.use_existing_instance ? data.aws_db_instance.existing[0].port : aws_db_instance.main[0].port
}

# Outputs
output "db_instance_id" {
  description = "ID of the RDS instance"
  value       = local.db_instance_id
}

output "db_instance_endpoint" {
  description = "Endpoint of the RDS instance"
  value       = local.db_instance_endpoint
}

output "db_instance_identifier" {
  description = "Identifier of the RDS instance"
  value       = var.use_existing_instance ? data.aws_db_instance.existing[0].db_name : aws_db_instance.main[0].identifier
}

output "db_instance_port" {
  description = "Port of the RDS instance"
  value       = local.db_instance_port
}

output "db_subnet_group_name" {
  description = "Name of the DB subnet group"
  value       = local.subnet_group_name
} 