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

# S3 Buckets
resource "aws_s3_bucket" "buckets" {
  for_each = var.bucket_names

  bucket = "${var.name_prefix}-${each.value}"

  tags = var.tags
}

# S3 Bucket Versioning
resource "aws_s3_bucket_versioning" "buckets" {
  for_each = aws_s3_bucket.buckets

  bucket = each.value.id
  versioning_configuration {
    status = "Enabled"
  }
}

# S3 Bucket Server Side Encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "buckets" {
  for_each = aws_s3_bucket.buckets

  bucket = each.value.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
      kms_master_key_id = var.kms_key_id
    }
  }
}

# S3 Bucket Lifecycle Rules
resource "aws_s3_bucket_lifecycle_configuration" "buckets" {
  for_each = {
    for k, v in var.lifecycle_rules : k => v
    if v.enabled
  }

  bucket = aws_s3_bucket.buckets[each.key].id

  dynamic "rule" {
    for_each = each.value.transitions
    content {
      id     = "transition-to-${rule.value.storage_class}"
      status = "Enabled"

      filter {
        prefix = each.value.prefix
      }

      transition {
        days          = rule.value.days
        storage_class = rule.value.storage_class
      }
    }
  }

  rule {
    id     = "expire-old-versions"
    status = "Enabled"

    filter {
      prefix = each.value.prefix
    }

    expiration {
      days = each.value.expiration.days
    }
  }
}

# S3 Bucket CORS Configuration
resource "aws_s3_bucket_cors_configuration" "buckets" {
  for_each = var.cors_rules

  bucket = aws_s3_bucket.buckets[each.key].id

  cors_rule {
    allowed_headers = each.value.allowed_headers
    allowed_methods = each.value.allowed_methods
    allowed_origins = each.value.allowed_origins
    expose_headers  = each.value.expose_headers
    max_age_seconds = each.value.max_age_seconds
  }
}

# S3 Bucket Public Access Block
resource "aws_s3_bucket_public_access_block" "buckets" {
  for_each = aws_s3_bucket.buckets

  bucket = each.value.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# S3 Bucket Policy
resource "aws_s3_bucket_policy" "buckets" {
  for_each = {
    for k, v in aws_s3_bucket.buckets : k => v
    if k == "uploads" || k == "static"
  }

  bucket = each.value.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowCloudFrontServicePrincipal"
        Effect    = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action   = "s3:GetObject"
        Resource = "${each.value.arn}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = var.cloudfront_distribution_arn
          }
        }
      }
    ]
  })
} 