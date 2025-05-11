# RDS Instance
resource "aws_db_instance" "main" {
  identifier           = "${var.name_prefix}-rds"
  engine              = "postgres"
  engine_version      = "14.7"
  instance_class      = var.instance_class
  allocated_storage   = var.allocated_storage
  storage_type        = "gp3"
  storage_encrypted   = true
  kms_key_id          = var.kms_key_id

  db_name             = var.db_name
  username            = var.db_username
  password            = var.db_password

  vpc_security_group_ids = [aws_security_group.rds.id]
  db_subnet_group_name   = aws_db_subnet_group.main.name

  backup_retention_period = var.environment == "prod" ? 7 : 1
  backup_window          = "03:00-04:00"
  maintenance_window     = "Mon:04:00-Mon:05:00"

  multi_az               = var.environment == "prod"
  publicly_accessible    = false
  skip_final_snapshot    = var.environment != "prod"
  deletion_protection    = var.environment == "prod"

  performance_insights_enabled = true
  monitoring_interval         = 60
  monitoring_role_arn         = aws_iam_role.rds_monitoring.arn

  parameter_group_name = aws_db_parameter_group.main.name
  option_group_name    = aws_db_option_group.main.name

  tags = var.tags
}

# RDS Parameter Group
resource "aws_db_parameter_group" "main" {
  name   = "${var.name_prefix}-pg"
  family = "postgres14"

  parameter {
    name  = "log_connections"
    value = "1"
  }

  parameter {
    name  = "log_disconnections"
    value = "1"
  }

  parameter {
    name  = "log_statement"
    value = "ddl"
  }

  parameter {
    name  = "log_min_duration_statement"
    value = "1000"
  }

  tags = var.tags
}

# RDS Option Group
resource "aws_db_option_group" "main" {
  name                     = "${var.name_prefix}-og"
  option_group_description = "Option group for ${var.name_prefix} RDS instance"
  engine_name              = "postgres"
  major_engine_version     = "14"

  option {
    option_name = "pgAudit"
  }

  tags = var.tags
}

# RDS Subnet Group
resource "aws_db_subnet_group" "main" {
  name       = "${var.name_prefix}-subnet-group"
  subnet_ids = var.private_subnet_ids

  tags = var.tags
}

# RDS Security Group
resource "aws_security_group" "rds" {
  name        = "${var.name_prefix}-rds-sg"
  description = "Security group for RDS instance"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [var.ecs_security_group_id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = var.tags
}

# IAM Role for RDS Monitoring
resource "aws_iam_role" "rds_monitoring" {
  name = "${var.name_prefix}-rds-monitoring-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "monitoring.rds.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

# IAM Policy for RDS Monitoring
resource "aws_iam_role_policy_attachment" "rds_monitoring" {
  role       = aws_iam_role.rds_monitoring.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
} 