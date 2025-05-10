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

output "client_branch_urls" {
  description = "URLs for each branch of the client app"
  value = {
    dev     = aws_amplify_branch.client_dev.url
    qa      = aws_amplify_branch.client_qa.url
    staging = aws_amplify_branch.client_staging.url
    main    = aws_amplify_branch.client_main.url
  }
}

output "admin_branch_urls" {
  description = "URLs for each branch of the admin app"
  value = {
    dev     = aws_amplify_branch.admin_dev.url
    qa      = aws_amplify_branch.admin_qa.url
    staging = aws_amplify_branch.admin_staging.url
    main    = aws_amplify_branch.admin_main.url
  }
} 