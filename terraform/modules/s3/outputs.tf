output "bucket_name" {
  description = "Name of the static assets bucket"
  value       = aws_s3_bucket.static.bucket
} 