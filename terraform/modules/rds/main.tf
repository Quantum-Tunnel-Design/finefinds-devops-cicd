# Get database password from Secrets Manager
# data "aws_secretsmanager_secret" "db_password" { # Not needed if ARN directly points to the secret
#   arn = var.db_password_arn
# }

# Fetch database credentials from AWS Secrets Manager
data "aws_secretsmanager_secret_version" "db_credentials" {
  secret_id = var.db_password_arn
}

locals {
  db_credentials = jsondecode(data.aws_secretsmanager_secret_version.db_credentials.secret_string)
  db_password    = local.db_credentials.password
  db_username    = local.db_credentials.username
}

# Reference existing RDS instance if flag is set
data "aws_db_instance" "existing" {
  count = var.use_existing_instance ? 1 : 0
  db_instance_identifier = "${var.project}-${var.environment}-db"
}

# Reference existing subnet group if flag is set
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
    from_port   = var.db_port
    to_port     = var.db_port
    protocol    = "tcp"
    cidr_blocks = var.vpc_cidr_blocks
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = var.security_group_name
  })

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

# RDS Instance (only created if not using existing)
resource "aws_db_instance" "main" {
  count                = var.use_existing_instance ? 0 : 1
  identifier           = var.name
  engine               = var.db_engine
  engine_version       = var.engine_version
  instance_class       = var.db_instance_class
  allocated_storage    = var.allocated_storage
  storage_type         = "gp2"
  storage_encrypted    = true
  kms_key_id           = var.kms_key_id
  db_name              = var.db_name
  username             = local.db_username
  password             = local.db_password
  skip_final_snapshot  = var.skip_final_snapshot
  deletion_protection  = true

  vpc_security_group_ids = [aws_security_group.main.id]
  db_subnet_group_name   = aws_db_subnet_group.main.name

  backup_retention_period = 7
  backup_window           = "03:00-04:00"
  maintenance_window      = "Mon:04:00-Mon:05:00"
  multi_az                = false
  publicly_accessible     = false

  enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]
  performance_insights_enabled    = true
  monitoring_interval             = 60

  tags = var.tags

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [aws_db_subnet_group.main]
}

# Local references
locals {
  db_instance_id       = var.use_existing_instance ? data.aws_db_instance.existing[0].id : aws_db_instance.main[0].id
  db_instance_endpoint = var.use_existing_instance ? data.aws_db_instance.existing[0].endpoint : aws_db_instance.main[0].endpoint
  db_instance_port     = var.use_existing_instance ? data.aws_db_instance.existing[0].port : aws_db_instance.main[0].port
}