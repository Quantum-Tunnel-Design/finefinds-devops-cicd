output "client_app_id" {
  description = "ID of the client Amplify app"
  value       = aws_amplify_app.client.id
}

output "admin_app_id" {
  description = "ID of the admin Amplify app"
  value       = aws_amplify_app.admin.id
}

output "client_domain" {
  description = "Domain of the client Amplify app"
  value       = aws_amplify_app.client.default_domain
}

output "admin_domain" {
  description = "Domain of the admin Amplify app"
  value       = aws_amplify_app.admin.default_domain
}

output "client_branch_arns" {
  description = "ARNs of the client app branches"
  value = {
    dev     = aws_amplify_branch.client_dev.arn
    qa      = aws_amplify_branch.client_qa.arn
    staging = aws_amplify_branch.client_staging.arn
    main    = aws_amplify_branch.client_main.arn
  }
}

output "admin_branch_arns" {
  description = "ARNs of the admin app branches"
  value = {
    dev     = aws_amplify_branch.admin_dev.arn
    qa      = aws_amplify_branch.admin_qa.arn
    staging = aws_amplify_branch.admin_staging.arn
    main    = aws_amplify_branch.admin_main.arn
  }
} 