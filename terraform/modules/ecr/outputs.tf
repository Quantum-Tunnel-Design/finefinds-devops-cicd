output "client_ecr_repository_arn" {
  value = aws_ecr_repository.client.arn
}

output "admin_ecr_repository_arn" {
  value = aws_ecr_repository.admin.arn
}