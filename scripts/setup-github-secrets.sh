#!/bin/bash

# Check if GitHub CLI is installed
if ! command -v gh &> /dev/null; then
    echo "GitHub CLI is not installed. Please install it first."
    exit 1
fi

# Check if required environment variables are set
if [ -z "$SONAR_TOKEN" ] || [ -z "$SONAR_HOST_URL" ]; then
    echo "Please set SONAR_TOKEN and SONAR_HOST_URL environment variables"
    exit 1
fi

# Define valid environments
VALID_BRANCHES=("main" "dev" "qa" "staging" "sandbox")
VALID_ENVS=("prod" "dev" "qa" "staging" "sandbox")

# Function to convert to uppercase (POSIX compliant)
to_upper() {
    echo "$1" | tr '[:lower:]' '[:upper:]'
}

# Function to get environment name from branch
get_env_from_branch() {
    local branch=$1
    case "$branch" in
        "main")
            echo "prod"
            ;;
        "dev"|"qa"|"staging"|"sandbox")
            echo "$branch"
            ;;
        *)
            echo ""
            ;;
    esac
}

# Function to validate environment names
validate_environments() {
    for branch in "${VALID_BRANCHES[@]}"; do
        local env
        env=$(get_env_from_branch "$branch")
        if [ -z "$env" ]; then
            echo "Error: Invalid branch name: $branch"
            exit 1
        fi
    done
}

# Function to create environment if it doesn't exist
create_environment() {
    local env=$1
    echo "Creating environment: $env"
    
    # Check if environment exists
    if ! gh api "repos/:owner/:repo/environments/$env" &> /dev/null; then
        if ! gh api repos/:owner/:repo/environments -f name="$env" &> /dev/null; then
            echo "Error: Failed to create environment: $env"
            return 1
        fi
    fi
    return 0
}

# Function to set a secret with error handling
set_secret() {
    local name=$1
    local value=$2
    local env=$3
    
    if ! gh secret set "$name" --body "$value" --env "$env" &> /dev/null; then
        echo "Error: Failed to set secret $name for environment $env"
        return 1
    fi
    return 0
}

# Function to set secrets for an environment
set_environment_secrets() {
    local branch=$1
    local env
    local aws_access_key_var
    local aws_secret_key_var
    local errors=0
    
    env=$(get_env_from_branch "$branch")
    aws_access_key_var="AWS_$(to_upper "$env")_ACCESS_KEY"
    aws_secret_key_var="AWS_$(to_upper "$env")_SECRET_KEY"
    
    echo "Setting secrets for environment: $env"
    
    # Create environment if it doesn't exist
    if ! create_environment "$env"; then
        echo "Error: Failed to create environment $env"
        return 1
    fi
    
    # Set SonarQube secrets
    echo "Setting SonarQube secrets for $env"
    if ! set_secret "SONAR_TOKEN" "$SONAR_TOKEN" "$env"; then
        errors=$((errors + 1))
    fi
    if ! set_secret "SONAR_HOST_URL" "$SONAR_HOST_URL" "$env"; then
        errors=$((errors + 1))
    fi
    
    # Set AWS secrets
    echo "Setting AWS secrets for $env"
    if [ -n "${!aws_access_key_var}" ] && [ -n "${!aws_secret_key_var}" ]; then
        if ! set_secret "AWS_ACCESS_KEY_ID" "${!aws_access_key_var}" "$env"; then
            errors=$((errors + 1))
        fi
        if ! set_secret "AWS_SECRET_ACCESS_KEY" "${!aws_secret_key_var}" "$env"; then
            errors=$((errors + 1))
        fi
    else
        echo "Warning: AWS credentials not set for $env environment"
    fi
    
    # Set AWS region
    if ! set_secret "AWS_REGION" "us-east-1" "$env"; then
        errors=$((errors + 1))
    fi
    
    # Verify secrets
    echo "Verifying secrets for $env"
    if ! gh secret list --env "$env" &> /dev/null; then
        echo "Error: Failed to list secrets for environment $env"
        errors=$((errors + 1))
    fi
    
    return $errors
}

# Validate environments
validate_environments

# Set up secrets for each environment
total_errors=0

echo "Setting up secrets for production (main) environment"
if ! set_environment_secrets "main"; then
    total_errors=$((total_errors + 1))
fi

echo "Setting up secrets for staging environment"
if ! set_environment_secrets "staging"; then
    total_errors=$((total_errors + 1))
fi

echo "Setting up secrets for development environment"
if ! set_environment_secrets "dev"; then
    total_errors=$((total_errors + 1))
fi

echo "Setting up secrets for QA environment"
if ! set_environment_secrets "qa"; then
    total_errors=$((total_errors + 1))
fi

echo "Setting up secrets for sandbox environment"
if ! set_environment_secrets "sandbox"; then
    total_errors=$((total_errors + 1))
fi

if [ $total_errors -eq 0 ]; then
    echo "GitHub secrets setup completed successfully!"
else
    echo "GitHub secrets setup completed with $total_errors errors"
    exit 1
fi 