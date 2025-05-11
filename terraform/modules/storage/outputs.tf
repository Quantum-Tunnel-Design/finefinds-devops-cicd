output "rds_endpoint" {
  description = "Endpoint of the RDS instance"
  value       = aws_db_instance.main.endpoint
}

output "rds_port" {
  description = "Port of the RDS instance"
  value       = aws_db_instance.main.port
}

# output "mongodb_private_ip" { # REMOVED
#   description = "Private IP of the MongoDB instance"
#   value       = var.use_existing_cluster ? null : aws_instance.mongodb[0].private_ip
# }
# 
# output "mongodb_ebs_volume_id" { # REMOVED
#   description = "ID of the MongoDB EBS volume"
#   value       = var.use_existing_cluster ? null : aws_ebs_volume.mongodb_data[0].id
# }

output "bucket_ids" {
  description = "Map of bucket names to their IDs"
  value       = { for k, v in aws_s3_bucket.buckets : k => v.id }
}

output "bucket_arns" {
  description = "Map of bucket names to their ARNs"
  value       = { for k, v in aws_s3_bucket.buckets : k => v.arn }
}

output "bucket_domain_names" {
  description = "Map of bucket names to their domain names"
  value       = { for k, v in aws_s3_bucket.buckets : k => v.bucket_domain_name }
}

output "bucket_regional_domain_names" {
  description = "Map of bucket names to their regional domain names"
  value       = { for k, v in aws_s3_bucket.buckets : k => v.bucket_regional_domain_name }
} 