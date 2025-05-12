#!/bin/bash

# AWS Account and Region
export AWS_ACCOUNT_ID="891076991993"
export AWS_REGION="us-east-1"

# GitHub Repository Information
export REPO_ORG="Quantum-Tunnel-Design"
export REPO_NAME="finefinds-devops-cicd"

# Slack Webhook URL for DevOps
export SLACK_WEBHOOK_URL_DEVOPS="https://hooks.slack.com/services/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"
export SLACK_CHANNEL_DEVOPS="#devops" 
export SLACK_BOT_DEVOPS_TOKEN="xoxb-8896608936544-8881125635028-bZjiFXcelFRUOE6rwZEsbYpr"

# SonarQube Configuration
export SONAR_TOKEN="your-sonarqube-token"
export SONAR_HOST_URL="https://sonarqube.your-domain.com"

# GitHub Token (for repository access)
export SOURCE_TOKEN="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"

# Client and Admin Repository URLs
export CLIENT_REPOSITORY="https://github.com/Quantum-Tunnel-Design/finefinds-client-web-app.git"
export ADMIN_REPOSITORY="https://github.com/Quantum-Tunnel-Design/finefinds-admin.git"

# Alert Email
export ALERT_EMAIL="amal.c.gamage@gmail.com"

# OIDC Configuration
export OIDC_PROVIDER_ARN="arn:aws:iam::${AWS_ACCOUNT_ID}:oidc-provider/token.actions.githubusercontent.com"
export OIDC_THUMBPRINT="6938fd4d98bab03faadb97b34396831e3780aea1"

