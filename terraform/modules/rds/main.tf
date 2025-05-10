# RDS Subnet Group
resource "aws_db_subnet_group" "main" {
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

  lifecycle {
    prevent_destroy = true
  }
}

# RDS Instance
resource "aws_db_instance" "main" {
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

  vpc_security_group_ids = [aws_security_group.rds.id]
  db_subnet_group_name   = aws_db_subnet_group.main.name

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

output "db_subnet_group_name" {
  description = "Name of the DB subnet group"
  value       = aws_db_subnet_group.main.name
} 