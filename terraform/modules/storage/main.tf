# S3 Bucket Suffix
resource "random_id" "bucket_suffix" {
  byte_length = 4
}

# S3 Buckets
resource "aws_s3_bucket" "buckets" {
  for_each = var.bucket_names

  bucket = "${var.name_prefix}-${each.value}-${random_id.bucket_suffix.hex}"

  tags = var.tags
}

# S3 Bucket Versioning
resource "aws_s3_bucket_versioning" "buckets" {
  for_each = var.bucket_names

  bucket = aws_s3_bucket.buckets[each.key].id
  versioning_configuration {
    status = "Enabled"
  }
}

# S3 Bucket Server Side Encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "buckets" {
  for_each = var.bucket_names

  bucket = aws_s3_bucket.buckets[each.key].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = var.kms_key_id != null ? "aws:kms" : "AES256"
      kms_master_key_id = var.kms_key_id != null ? var.kms_key_id : null
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
        prefix = each.value.prefix # Ensure 'prefix' is a valid attribute in var.lifecycle_rules.transitions objects, or use a default/empty string.
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
      prefix = each.value.prefix # Ensure 'prefix' is a valid attribute in var.lifecycle_rules object that 'each.value' refers to.
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
  for_each = var.bucket_names

  bucket = aws_s3_bucket.buckets[each.key].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# S3 Bucket Policy
resource "aws_s3_bucket_policy" "buckets" {
  for_each = { 
    for k, v_unused_in_value in var.bucket_names : k => aws_s3_bucket.buckets[k]
    if (k == "uploads" || k == "static") && var.cloudfront_distribution_arn != null
  }

  bucket = each.value.id # each.value is now the bucket object corresponding to the filtered key

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

# S3 Bucket for CloudTrail
resource "aws_s3_bucket" "cloudtrail" {
  count  = var.include_cloudtrail ? 1 : 0
  bucket = "${var.name_prefix}-cloudtrail-${random_id.bucket_suffix.hex}"
  tags   = var.tags
}

resource "aws_s3_bucket_versioning" "cloudtrail" {
  count  = var.include_cloudtrail ? 1 : 0
  bucket = aws_s3_bucket.cloudtrail[0].id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "cloudtrail" {
  count  = var.include_cloudtrail && var.cloudtrail_lifecycle.enabled ? 1 : 0
  bucket = aws_s3_bucket.cloudtrail[0].id

  rule {
    id     = "cleanup"
    status = "Enabled"
    filter {
      prefix = "AWSLogs/"
    }
    expiration {
      days = var.cloudtrail_lifecycle.expiration_days
    }
  }
}
data "aws_caller_identity" "current" {}

resource "aws_s3_bucket_policy" "cloudtrail" {
  bucket   = aws_s3_bucket.cloudtrail[0].id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid       = "AWSCloudTrailAclCheck",
        Effect    = "Allow",
        Principal = { Service = "cloudtrail.amazonaws.com" },
        Action    = "s3:GetBucketAcl",
        Resource  = aws_s3_bucket.cloudtrail[0].arn
      },
      {
        Sid       = "AWSCloudTrailWrite",
        Effect    = "Allow",
        Principal = { Service = "cloudtrail.amazonaws.com" },
        Action    = "s3:PutObject",
        Resource  = "${aws_s3_bucket.cloudtrail[0].arn}/AWSLogs/${data.aws_caller_identity.current.account_id}/*",
        Condition = { StringEquals = { "s3:x-amz-acl" = "bucket-owner-full-control" } }
      }
    ]
  })
}