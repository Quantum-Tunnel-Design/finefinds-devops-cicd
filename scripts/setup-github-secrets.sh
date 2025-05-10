#!/bin/bash

# Check if gh CLI is installed
if ! command -v gh &> /dev/null; then
    echo "GitHub CLI (gh) is not installed. Please install it first."
    exit 1
fi

# Check if user is authenticated
if ! gh auth status &> /dev/null; then
    echo "Please login to GitHub first using 'gh auth login'"
    exit 1
fi

# Function to prompt for secret value
prompt_secret() {
    local secret_name=$1
    local secret_value
    read -sp "Enter value for $secret_name: " secret_value
    echo
    echo "$secret_value"
}

# Set AWS credentials
AWS_ACCESS_KEY_ID=$(prompt_secret "AWS_ACCESS_KEY_ID")
AWS_SECRET_ACCESS_KEY=$(prompt_secret "AWS_SECRET_ACCESS_KEY")
AWS_REGION=$(prompt_secret "AWS_REGION")

# Set database passwords
DB_PASSWORD=$(prompt_secret "DB_PASSWORD")
SONARQUBE_DB_PASSWORD=$(prompt_secret "SONARQUBE_DB_PASSWORD")
MONGODB_ADMIN_PASSWORD=$(prompt_secret "MONGODB_ADMIN_PASSWORD")

# Set application secrets
JWT_SECRET=$(prompt_secret "JWT_SECRET")
COGNITO_CLIENT_SECRET=$(prompt_secret "COGNITO_CLIENT_SECRET")

# Set secrets in GitHub
echo "Setting secrets in GitHub..."
gh secret set AWS_ACCESS_KEY_ID --body "$AWS_ACCESS_KEY_ID"
gh secret set AWS_SECRET_ACCESS_KEY --body "$AWS_SECRET_ACCESS_KEY"
gh secret set AWS_REGION --body "$AWS_REGION"
gh secret set DB_PASSWORD --body "$DB_PASSWORD"
gh secret set SONARQUBE_DB_PASSWORD --body "$SONARQUBE_DB_PASSWORD"
gh secret set MONGODB_ADMIN_PASSWORD --body "$MONGODB_ADMIN_PASSWORD"
gh secret set JWT_SECRET --body "$JWT_SECRET"
gh secret set COGNITO_CLIENT_SECRET --body "$COGNITO_CLIENT_SECRET"

echo "All secrets have been set successfully!" 