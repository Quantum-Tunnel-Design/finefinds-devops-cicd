output "rds_endpoint" {
  description = "Endpoint of the RDS instance"
  value       = aws_db_instance.main.endpoint
}

output "rds_port" {
  description = "Port of the RDS instance"
  value       = aws_db_instance.main.port
}

output "mongodb_private_ip" {
  description = "Private IP of the MongoDB instance"
  value       = var.use_existing_cluster ? null : aws_instance.mongodb[0].private_ip
}

output "mongodb_ebs_volume_id" {
  description = "ID of the MongoDB EBS volume"
  value       = var.use_existing_cluster ? null : aws_ebs_volume.mongodb_data[0].id
}

output "static_bucket_name" {
  description = "Name of the static assets S3 bucket"
  value       = aws_s3_bucket.static.bucket
}

output "static_bucket_arn" {
  description = "ARN of the static assets S3 bucket"
  value       = aws_s3_bucket.static.arn
}

output "static_bucket_domain_name" {
  description = "Domain name of the static assets S3 bucket"
  value       = aws_s3_bucket.static.bucket_domain_name
} 