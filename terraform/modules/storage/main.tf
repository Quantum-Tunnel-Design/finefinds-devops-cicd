# RDS Instance
resource "aws_db_instance" "main" {
  identifier           = "${var.name_prefix}-rds"
  engine              = "postgres"
  engine_version      = "14.7"
  instance_class      = var.db_instance_class
  allocated_storage   = var.allocated_storage
  storage_type        = "gp2"
  storage_encrypted   = true

  db_name             = var.db_name
  username            = var.db_username
  password            = var.db_password

  vpc_security_group_ids = [aws_security_group.rds.id]
  db_subnet_group_name   = aws_db_subnet_group.main.name

  backup_retention_period = 7
  backup_window          = "03:00-04:00"
  maintenance_window     = "Mon:04:00-Mon:05:00"

  multi_az               = var.environment == "prod"
  skip_final_snapshot    = var.skip_final_snapshot
  deletion_protection    = var.environment == "prod"

  tags = var.tags
}

# RDS Subnet Group
resource "aws_db_subnet_group" "main" {
  name       = "${var.name_prefix}-rds-subnet-group"
  subnet_ids = var.private_subnet_ids

  tags = var.tags
}

# RDS Security Group
resource "aws_security_group" "rds" {
  name        = "${var.name_prefix}-rds-sg"
  description = "Security group for RDS instance"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = var.vpc_cidr_blocks
  }

  tags = var.tags
}

# MongoDB EC2 Instance
resource "aws_instance" "mongodb" {
  count = var.use_existing_cluster ? 0 : 1

  ami           = var.mongodb_ami
  instance_type = var.mongodb_instance_type
  subnet_id     = var.private_subnet_ids[0]

  vpc_security_group_ids = [aws_security_group.mongodb.id]
  iam_instance_profile   = aws_iam_instance_profile.mongodb.name

  root_block_device {
    volume_size = 20
    encrypted   = true
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-mongodb"
    }
  )
}

# MongoDB EBS Volume
resource "aws_ebs_volume" "mongodb_data" {
  count = var.use_existing_cluster ? 0 : 1

  availability_zone = aws_instance.mongodb[0].availability_zone
  size              = 20
  encrypted         = true

  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-mongodb-data"
    }
  )
}

# MongoDB Security Group
resource "aws_security_group" "mongodb" {
  name        = "${var.name_prefix}-mongodb-sg"
  description = "Security group for MongoDB instance"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 27017
    to_port     = 27017
    protocol    = "tcp"
    cidr_blocks = var.vpc_cidr_blocks
  }

  tags = var.tags
}

# MongoDB IAM Role
resource "aws_iam_role" "mongodb" {
  name = "${var.name_prefix}-mongodb-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

# MongoDB IAM Instance Profile
resource "aws_iam_instance_profile" "mongodb" {
  name = "${var.name_prefix}-mongodb-profile"
  role = aws_iam_role.mongodb.name
}

# S3 Bucket for Static Assets
resource "aws_s3_bucket" "static" {
  bucket = "${var.name_prefix}-static-assets"

  tags = var.tags
}

# S3 Bucket Versioning
resource "aws_s3_bucket_versioning" "static" {
  bucket = aws_s3_bucket.static.id
  versioning_configuration {
    status = "Enabled"
  }
}

# S3 Bucket Server Side Encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "static" {
  bucket = aws_s3_bucket.static.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# S3 Bucket Lifecycle Rules
resource "aws_s3_bucket_lifecycle_configuration" "uploads" {
  bucket = aws_s3_bucket.uploads.id

  rule {
    id     = "cleanup-old-versions"
    status = "Enabled"

    filter {
      prefix = ""
    }

    noncurrent_version_expiration {
      noncurrent_days = 90
    }
  }

  rule {
    id     = "delete-incomplete-multipart-uploads"
    status = "Enabled"

    filter {
      prefix = ""
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "backups" {
  bucket = aws_s3_bucket.backups.id

  rule {
    id     = "transition-to-ia"
    status = "Enabled"

    filter {
      prefix = ""
    }

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = 90
      storage_class = "GLACIER"
    }

    expiration {
      days = 365
    }
  }
}

# S3 Bucket CORS Configuration
resource "aws_s3_bucket_cors_configuration" "static" {
  bucket = aws_s3_bucket.static.id

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET", "HEAD"]
    allowed_origins = ["*"]
    expose_headers  = ["ETag"]
    max_age_seconds = 3000
  }
} 