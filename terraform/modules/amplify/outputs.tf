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

output "client_amplify_domain_name" {
  description = "Domain name of the client Amplify app"
  value       = aws_amplify_domain_association.client.domain_name
}

output "admin_amplify_domain_name" {
  description = "Domain name of the admin Amplify app"
  value       = aws_amplify_domain_association.admin.domain_name
}

output "client_amplify_app_url" {
  description = "URL of the client Amplify app"
  value       = "https://${var.environment}.${var.domain_name}"
}

output "admin_amplify_app_url" {
  description = "URL of the admin Amplify app"
  value       = "https://${var.environment}-admin.${var.domain_name}"
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {} 