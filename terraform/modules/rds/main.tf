# Get database password from Secrets Manager
# data "aws_secretsmanager_secret" "db_password" { # Not needed if ARN directly points to the secret
#   arn = var.db_password_arn
# }

data "aws_secretsmanager_secret_version" "db_credentials" { # Renamed for clarity
  secret_id = var.db_password_arn # ARN for the secret finefinds/dev/database
}

locals {
  db_credentials = jsondecode(data.aws_secretsmanager_secret_version.db_credentials.secret_string)
  db_password    = local.db_credentials.password
  # db_username    = local.db_credentials.username # Can be used if RDS module needs to override var.db_username
}

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

# RDS Security Group
resource "aws_security_group" "main" {
  name        = var.security_group_name
  description = "Security group for RDS instance"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    cidr_blocks     = var.vpc_cidr_blocks
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    var.tags,
    {
      Name = var.security_group_name
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

# RDS Subnet Group
resource "aws_db_subnet_group" "main" {
  name       = "${var.name}-subnet-group"
  subnet_ids = var.subnet_ids

  tags = var.tags
}

# RDS Instance
resource "aws_db_instance" "main" {
  identifier           = var.name
  engine              = "postgres"
  engine_version      = "14.7"
  instance_class      = var.db_instance_class
  allocated_storage   = var.allocated_storage
  storage_type        = "gp2"
  db_name             = var.db_name
  username            = var.db_username # This uses the module input, not from secret
  password            = local.db_password
  skip_final_snapshot = var.skip_final_snapshot

  vpc_security_group_ids = [aws_security_group.main.id]
  db_subnet_group_name   = aws_db_subnet_group.main.name

  backup_retention_period = 7
  backup_window          = "03:00-04:00"
  maintenance_window     = "Mon:04:00-Mon:05:00"

  multi_az               = false
  publicly_accessible    = false
  deletion_protection    = true

  tags = var.tags

  lifecycle {
    create_before_destroy = true
  }
}

# Use existing or new instance
locals {
  db_instance_id       = var.use_existing_instance ? data.aws_db_instance.existing[0].id : aws_db_instance.main.id
  db_instance_endpoint = var.use_existing_instance ? data.aws_db_instance.existing[0].endpoint : aws_db_instance.main.endpoint
  db_instance_port     = var.use_existing_instance ? data.aws_db_instance.existing[0].port : aws_db_instance.main.port
} 