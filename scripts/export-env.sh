#!/bin/bash

# AWS Account and Region
export AWS_ACCOUNT_ID="891076991993"
export AWS_REGION="us-east-1"

# AWS Role ARN for GitHub Actions
export AWS_ROLE_ARN="arn:aws:iam::${AWS_ACCOUNT_ID}:role/github-actions-role"

# Slack Webhook URL for DevOps
export SLACK_WEBHOOK_URL_DEVOPS="https://hooks.slack.com/services/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"
export SLACK_CHANNEL_DEVOPS="#ff-cicd-devops" 
export SLACK_BOT_DEVOPS_TOKEN="xoxb-8896608936544-8881125635028-bZjiFXcelFRUOE6rwZEsbYpr"

# SonarQube Configuration
export SONAR_TOKEN="your-sonarqube-token"
export SONAR_HOST_URL="https://sonarqube.your-domain.com"

# GitHub Token (for repository access)
export SOURCE_TOKEN="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"

# Environment-specific AWS credentials (if needed)
export AWS_PROD_ACCESS_KEY="AKIA466CT3P4SG5MUPOD"
export AWS_PROD_SECRET_KEY="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"
export AWS_STAGING_ACCESS_KEY="AKIA466CT3P4SG5MUPOD"
export AWS_STAGING_SECRET_KEY="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"
export AWS_DEV_ACCESS_KEY="AKIA466CT3P4SG5MUPOD"
export AWS_DEV_SECRET_KEY="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"
export AWS_QA_ACCESS_KEY="AKIA466CT3P4SG5MUPOD"
export AWS_QA_SECRET_KEY="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"
export AWS_SANDBOX_ACCESS_KEY="AKIA466CT3P4SG5MUPOD"
export AWS_SANDBOX_SECRET_KEY="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"

# Client and Admin Repository URLs
export CLIENT_REPOSITORY="https://github.com/Quantum-Tunnel-Design/finefinds-client-web-app.git"
export ADMIN_REPOSITORY="https://github.com/Quantum-Tunnel-Design/finefinds-admin.git"

# Alert Email
export ALERT_EMAIL="amal.c.gamage@gmail.com"

