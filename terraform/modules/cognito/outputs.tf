# Outputs for Client Pool
output "client_user_pool_id" {
  description = "ID of the Client Cognito User Pool"
  value       = aws_cognito_user_pool.client_pool.id
}

output "client_user_pool_arn" {
  description = "ARN of the Client Cognito User Pool"
  value       = aws_cognito_user_pool.client_pool.arn
}

output "client_app_client_id" {
  description = "ID of the Client App Cognito User Pool Client"
  value       = aws_cognito_user_pool_client.client_app.id
}

output "client_app_client_secret" {
  description = "Secret of the Client App Cognito User Pool Client"
  value       = aws_cognito_user_pool_client.client_app.client_secret
  sensitive   = true
}

output "client_pool_domain" {
  description = "Domain of the Client Cognito User Pool"
  value       = aws_cognito_user_pool_domain.client_pool_domain.domain
}

# Outputs for Admin Pool
output "admin_user_pool_id" {
  description = "ID of the Admin Cognito User Pool"
  value       = aws_cognito_user_pool.admin_pool.id
}

output "admin_user_pool_arn" {
  description = "ARN of the Admin Cognito User Pool"
  value       = aws_cognito_user_pool.admin_pool.arn
}

output "admin_app_client_id" {
  description = "ID of the Admin App Cognito User Pool Client"
  value       = aws_cognito_user_pool_client.admin_app.id
}

output "admin_app_client_secret" {
  description = "Secret of the Admin App Cognito User Pool Client"
  value       = aws_cognito_user_pool_client.admin_app.client_secret
  sensitive   = true
}

output "admin_pool_domain" {
  description = "Domain of the Admin Cognito User Pool"
  value       = aws_cognito_user_pool_domain.admin_pool_domain.domain
} 