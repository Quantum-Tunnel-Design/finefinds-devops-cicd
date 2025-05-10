#!/bin/bash

# Check if GitHub CLI is installed
if ! command -v gh &> /dev/null; then
    echo "GitHub CLI is not installed. Please install it first."
    exit 1
fi

# Define environment mapping using indexed arrays
BRANCHES=("main" "dev" "qa" "staging" "sandbox")
ENVIRONMENTS=("prod" "dev" "qa" "staging" "sandbox")

# Function to validate environment names
validate_environments() {
    local valid_envs=("main" "dev" "qa" "staging" "sandbox")
    for i in "${!BRANCHES[@]}"; do
        if [[ ! " ${valid_envs[@]} " =~ " ${BRANCHES[$i]} " ]]; then
            echo "Error: Invalid branch name: ${BRANCHES[$i]}"
            exit 1
        fi
    done
}

# Function to create or update environment protection rules
setup_environment_protection() {
    local branch=$1
    local env=$2
    local wait_timer=$3
    local required_reviewers=$4

    echo "Setting up protection rules for branch '$branch' (environment: $env)"
    
    # Create environment if it doesn't exist
    gh api repos/:owner/:repo/environments -f name="$env" || true

    # Set protection rules
    gh api repos/:owner/:repo/environments/"$env" \
        -f wait_timer="$wait_timer" \
        -f required_reviewers="$required_reviewers" \
        -f deployment_branch_policy='{"protected_branches":true,"custom_branches":["'"$branch"'"]}'
}

# Validate environments
validate_environments

# Set up protection rules for each environment
# Production (main branch)
setup_environment_protection "main" "prod" 30 2

# Staging
setup_environment_protection "staging" "staging" 15 1

# Development
setup_environment_protection "dev" "dev" 0 0

# QA
setup_environment_protection "qa" "qa" 0 0

# Sandbox
setup_environment_protection "sandbox" "sandbox" 0 0

echo "Environment protection rules setup completed!" 