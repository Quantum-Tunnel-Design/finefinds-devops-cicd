#!/bin/bash

# Check if GitHub CLI is installed
if ! command -v gh &> /dev/null; then
    echo "GitHub CLI is not installed. Please install it first."
    exit 1
fi

# Check if user is authenticated
if ! gh auth status &> /dev/null; then
    echo "Please login to GitHub first using 'gh auth login'"
    exit 1
fi

# Source the environment variables
source ./scripts/export-env.sh

# Function to set secrets for a specific environment
set_environment_secrets() {
    local env=$1
    echo "Setting secrets for environment: $env"
    
    # Set AWS Account ID and Region (common for all environments)
    gh secret set AWS_ACCOUNT_ID -b"$AWS_ACCOUNT_ID" --env "$env"
    gh secret set AWS_REGION -b"$AWS_REGION" --env "$env"
    gh secret set CLIENT_REPOSITORY -b"$CLIENT_REPOSITORY" --env "$env"
    gh secret set ADMIN_REPOSITORY -b"$ADMIN_REPOSITORY" --env "$env"
    gh secret set SOURCE_TOKEN -b"$SOURCE_TOKEN" --env "$env"
    gh secret set ALERT_EMAIL -b"$ALERT_EMAIL" --env "$env"
    gh secret set SLACK_WEBHOOK_URL_DEVOPS -b"$SLACK_WEBHOOK_URL_DEVOPS" --env "$env"
    gh secret set SLACK_CHANNEL_DEVOPS -b"$SLACK_CHANNEL_DEVOPS" --env "$env"
    gh secret set SLACK_BOT_DEVOPS_TOKEN -b"$SLACK_BOT_DEVOPS_TOKEN" --env "$env"
    
    # Set environment-specific AWS credentials
    case "$env" in
        "prod")
            gh secret set AWS_ACCESS_KEY_ID -b"$AWS_PROD_ACCESS_KEY" --env "$env"
            gh secret set AWS_SECRET_ACCESS_KEY -b"$AWS_PROD_SECRET_KEY" --env "$env"
            ;;
        "staging")
            gh secret set AWS_ACCESS_KEY_ID -b"$AWS_STAGING_ACCESS_KEY" --env "$env"
            gh secret set AWS_SECRET_ACCESS_KEY -b"$AWS_STAGING_SECRET_KEY" --env "$env"
            ;;
        "dev")
            gh secret set AWS_ACCESS_KEY_ID -b"$AWS_DEV_ACCESS_KEY" --env "$env"
            gh secret set AWS_SECRET_ACCESS_KEY -b"$AWS_DEV_SECRET_KEY" --env "$env"
            ;;
        "qa")
            gh secret set AWS_ACCESS_KEY_ID -b"$AWS_QA_ACCESS_KEY" --env "$env"
            gh secret set AWS_SECRET_ACCESS_KEY -b"$AWS_QA_SECRET_KEY" --env "$env"
            ;;
        "sandbox")
            gh secret set AWS_ACCESS_KEY_ID -b"$AWS_SANDBOX_ACCESS_KEY" --env "$env"
            gh secret set AWS_SECRET_ACCESS_KEY -b"$AWS_SANDBOX_SECRET_KEY" --env "$env"
            ;;
    esac
    
    # Set repository information (using non-GITHUB_ prefixed names)
    gh secret set REPO_ORG -b"$REPO_ORG" --env "$env"
    gh secret set REPO_NAME -b"$REPO_NAME" --env "$env"
    
    # Set new secrets for CDK workflow
    gh secret set SLACK_BOT_TOKEN -b"$SLACK_BOT_TOKEN" --env "$env"
    gh secret set SLACK_CHANNEL -b"$SLACK_CHANNEL" --env "$env"
    gh secret set AWS_ROLE_ARN -b"$AWS_ROLE_ARN" --env "$env"
    gh secret set SONAR_TOKEN -b"$SONAR_TOKEN" --env "$env"
    gh secret set SONAR_HOST_URL -b"$SONAR_HOST_URL" --env "$env"
    
    echo "✅ Secrets set for $env environment"
}

# Create environments if they don't exist
echo "Creating environments..."
gh api repos/:owner/:repo/environments -f name="prod" || true
gh api repos/:owner/:repo/environments -f name="staging" || true
gh api repos/:owner/:repo/environments -f name="dev" || true
gh api repos/:owner/:repo/environments -f name="qa" || true
gh api repos/:owner/:repo/environments -f name="sandbox" || true

# Set secrets for each environment
echo "Setting up secrets for each environment..."
set_environment_secrets "prod"
set_environment_secrets "staging"
set_environment_secrets "dev"
set_environment_secrets "qa"
set_environment_secrets "sandbox"

echo "✅ GitHub secrets setup completed for all environments!"

# Function to set secrets for a repository
set_repo_secrets() {
    local repo=$1
    echo "Setting secrets for repository: $repo"
    
    # Set GitHub token
    gh secret set SOURCE_TOKEN --body "$SOURCE_TOKEN" --repo "$repo"
    
    # Only set SonarQube secrets for non-devops repositories
    if [[ "$repo" != *"finefindslk-devops-cicd"* ]]; then
        gh secret set SONAR_TOKEN --body "$SONAR_TOKEN" --repo "$repo"
    fi
}

# Set secrets for client web app
set_repo_secrets "Quantum-Tunnel-Design/finefinds-client-web-app"

# Set secrets for admin dashboard
set_repo_secrets "Quantum-Tunnel-Design/finefinds-admin"

echo "GitHub secrets have been set successfully!" 