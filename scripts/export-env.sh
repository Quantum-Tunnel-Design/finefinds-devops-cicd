#!/bin/bash

# AWS Account and Region
export AWS_ACCOUNT_ID="your-aws-account-id"
export AWS_REGION="us-east-1"

# AWS Role ARN for GitHub Actions
export AWS_ROLE_ARN="arn:aws:iam::${AWS_ACCOUNT_ID}:role/github-actions-role"

# Slack Configuration
export SLACK_BOT_TOKEN="your-slack-bot-token"
export SLACK_CHANNEL="#deployments"

# SonarQube Configuration
export SONAR_TOKEN="your-sonarqube-token"
export SONAR_HOST_URL="https://sonarqube.your-domain.com"

# GitHub Token (for repository access)
export TF_VAR_github_token="your-github-token"

# Environment-specific AWS credentials (if needed)
export AWS_PROD_ACCESS_KEY="your-prod-access-key"
export AWS_PROD_SECRET_KEY="your-prod-secret-key"
export AWS_STAGING_ACCESS_KEY="your-staging-access-key"
export AWS_STAGING_SECRET_KEY="your-staging-secret-key"
export AWS_DEV_ACCESS_KEY="your-dev-access-key"
export AWS_DEV_SECRET_KEY="your-dev-secret-key"
export AWS_QA_ACCESS_KEY="your-qa-access-key"
export AWS_QA_SECRET_KEY="your-qa-secret-key"
export AWS_SANDBOX_ACCESS_KEY="your-sandbox-access-key"
export AWS_SANDBOX_SECRET_KEY="your-sandbox-secret-key"

# Repository Information
export REPO_ORG="your-github-org"
export REPO_NAME="your-repo-name"

# Client and Admin Repository URLs
export TF_VAR_client_repository="https://github.com/your-org/your-client-repo.git"
export TF_VAR_admin_repository="https://github.com/your-org/your-admin-repo.git"

# Alert Email
export TF_VAR_alert_email="your-alert-email@example.com"

# Slack Webhook URL for DevOps
export SLACK_WEBHOOK_URL_DEVOPS="your-slack-webhook-url"
export SLACK_CHANNEL_DEVOPS="#devops" 