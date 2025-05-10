#!/bin/bash

# Check if GitHub CLI is installed
if ! command -v gh &> /dev/null; then
    echo "GitHub CLI is not installed. Please install it first."
    exit 1
fi

# Define environment mapping
declare -A ENV_MAPPING=(
    ["main"]="prod"
    ["dev"]="dev"
    ["qa"]="qa"
    ["staging"]="staging"
    ["sandbox"]="sandbox"
)

# Function to validate environment names
validate_environments() {
    local valid_envs=("main" "dev" "qa" "staging" "sandbox")
    for env in "${!ENV_MAPPING[@]}"; do
        if [[ ! " ${valid_envs[@]} " =~ " ${env} " ]]; then
            echo "Error: Invalid branch name: $env"
            exit 1
        fi
    done
}

# Function to create or update environment protection rules
setup_environment_protection() {
    local branch=$1
    local env=${ENV_MAPPING[$branch]}
    local wait_timer=$2
    local required_reviewers=$3

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
setup_environment_protection "main" 30 2

# Staging
setup_environment_protection "staging" 15 1

# Development
setup_environment_protection "dev" 0 0

# QA
setup_environment_protection "qa" 0 0

# Sandbox
setup_environment_protection "sandbox" 0 0

echo "Environment protection rules setup completed!" 