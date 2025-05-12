output "client_ecr_repository_arn" {
  description = "ARN of the client ECR repository"
  value       = aws_ecr_repository.client.arn
}

output "admin_ecr_repository_arn" {
  description = "ARN of the admin ECR repository"
  value       = aws_ecr_repository.admin.arn
}

output "client_amplify_app_id" {
  description = "ID of the client Amplify app"
  value       = aws_amplify_app.client.id
}

output "admin_amplify_app_id" {
  description = "ID of the admin Amplify app"
  value       = aws_amplify_app.admin.id
}

output "client_amplify_app_arn" {
  description = "ARN of the client Amplify app"
  value       = aws_amplify_app.client.arn
}

output "admin_amplify_app_arn" {
  description = "ARN of the admin Amplify app"
  value       = aws_amplify_app.admin.arn
}

output "client_amplify_branch_name" {
  description = "Name of the client Amplify branch"
  value       = aws_amplify_branch.client.branch_name
}

output "admin_amplify_branch_name" {
  description = "Name of the admin Amplify branch"
  value       = aws_amplify_branch.admin.branch_name
}

output "client_amplify_app_url" {
  description = "URL of the client Amplify app (using default AWS domain)"
  value       = "https://${aws_amplify_app.client.id}.amplifyapp.com"
}

output "admin_amplify_app_url" {
  description = "URL of the admin Amplify app (using default AWS domain)"
  value       = "https://${aws_amplify_app.admin.id}.amplifyapp.com"
} 