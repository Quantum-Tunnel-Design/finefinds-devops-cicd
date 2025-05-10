output "ecr_repository_url" {
  description = "URL of the ECR repository"
  value       = aws_ecr_repository.main.repository_url
}

output "ecr_repository_arn" {
  description = "ARN of the ECR repository"
  value       = aws_ecr_repository.main.arn
}

output "amplify_app_id" {
  description = "ID of the Amplify app"
  value       = aws_amplify_app.main.id
}

output "amplify_app_arn" {
  description = "ARN of the Amplify app"
  value       = aws_amplify_app.main.arn
}

output "amplify_branch_name" {
  description = "Name of the Amplify branch"
  value       = aws_amplify_branch.main.branch_name
}

output "amplify_domain_name" {
  description = "Domain name of the Amplify app"
  value       = aws_amplify_domain_association.main.domain_name
}

output "amplify_app_url" {
  description = "URL of the Amplify app"
  value       = "https://${var.environment}.${var.domain_name}"
} 