#!/bin/bash

# Check if gh CLI is installed
if ! command -v gh &> /dev/null; then
    echo "GitHub CLI (gh) is not installed. Please install it first."
    exit 1
fi

# Check if required environment variables are set
if [ -z "$SONAR_TOKEN" ] || [ -z "$SONAR_HOST_URL" ]; then
    echo "Please set SONAR_TOKEN and SONAR_HOST_URL environment variables"
    exit 1
fi

# Function to create environment if it doesn't exist
create_environment() {
    local env=$1
    if ! gh api "repos/$(gh repo view --json nameWithOwner -q .nameWithOwner)/environments/$env" &> /dev/null; then
        echo "Creating environment: $env"
        gh api "repos/$(gh repo view --json nameWithOwner -q .nameWithOwner)/environments" \
            -X POST \
            -F name="$env" \
            -F wait_timer=0
    fi
}

# Function to set secrets for an environment
set_environment_secrets() {
    local env=$1
    local aws_access_key=$2
    local aws_secret_key=$3
    local aws_region=$4

    echo "Setting secrets for environment: $env"
    
    # Set SonarQube secrets
    gh secret set SONAR_TOKEN -b"$SONAR_TOKEN" -e"$env"
    gh secret set SONAR_HOST_URL -b"$SONAR_HOST_URL" -e"$env"
    
    # Set AWS secrets
    gh secret set AWS_ACCESS_KEY_ID -b"$aws_access_key" -e"$env"
    gh secret set AWS_SECRET_ACCESS_KEY -b"$aws_secret_key" -e"$env"
    gh secret set AWS_REGION -b"$aws_region" -e"$env"
}

# Create environments
for env in main dev qa staging sandbox; do
    create_environment "$env"
done

# Set secrets for each environment
# Production (main)
set_environment_secrets "main" \
    "$AWS_PROD_ACCESS_KEY" \
    "$AWS_PROD_SECRET_KEY" \
    "us-east-1"

# Staging
set_environment_secrets "staging" \
    "$AWS_STAGING_ACCESS_KEY" \
    "$AWS_STAGING_SECRET_KEY" \
    "us-east-1"

# Development
set_environment_secrets "dev" \
    "$AWS_DEV_ACCESS_KEY" \
    "$AWS_DEV_SECRET_KEY" \
    "us-east-1"

# QA
set_environment_secrets "qa" \
    "$AWS_QA_ACCESS_KEY" \
    "$AWS_QA_SECRET_KEY" \
    "us-east-1"

# Sandbox
set_environment_secrets "sandbox" \
    "$AWS_SANDBOX_ACCESS_KEY" \
    "$AWS_SANDBOX_SECRET_KEY" \
    "us-east-1"

echo "GitHub secrets setup completed!" 