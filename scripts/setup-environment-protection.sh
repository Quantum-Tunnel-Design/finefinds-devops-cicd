#!/bin/bash

# Check if gh CLI is installed
if ! command -v gh &> /dev/null; then
    echo "GitHub CLI (gh) is not installed. Please install it first."
    exit 1
fi

# Function to set up environment protection rules
setup_environment_protection() {
    local env=$1
    local wait_timer=$2
    local required_reviewers=$3

    echo "Setting up protection rules for environment: $env"
    
    # Create or update environment
    gh api "repos/$(gh repo view --json nameWithOwner -q .nameWithOwner)/environments" \
        -X POST \
        -F name="$env" \
        -F wait_timer="$wait_timer" \
        -F required_reviewers="$required_reviewers" \
        -F deployment_branch_policy='{"protected_branches": true, "custom_branches": []}'
}

# Set up protection rules for each environment
# Production (main) - Strict rules
setup_environment_protection "main" 30 2

# Staging - Moderate rules
setup_environment_protection "staging" 15 1

# Development - Basic rules
setup_environment_protection "dev" 0 0

# QA - Basic rules
setup_environment_protection "qa" 0 0

# Sandbox - Basic rules
setup_environment_protection "sandbox" 0 0

echo "Environment protection rules setup completed!" 