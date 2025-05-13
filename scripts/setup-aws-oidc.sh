#!/bin/bash

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
    echo "AWS CLI is not installed. Please install it first."
    exit 1
fi

# Check if required environment variables are set
if [ -z "$AWS_ACCOUNT_ID" ] || [ -z "$REPO_ORG" ] || [ -z "$REPO_NAME" ]; then
    echo "Please set AWS_ACCOUNT_ID, REPO_ORG, and REPO_NAME environment variables"
    exit 1
fi

echo "=== Environment Configuration ==="
echo "GitHub Organization: $REPO_ORG"
echo "GitHub Repository: $REPO_NAME"
echo "AWS Account ID: $AWS_ACCOUNT_ID"
echo "================================"

# Define valid environments
VALID_BRANCHES=("main" "dev" "qa" "staging" "sandbox")
VALID_ENVS=("prod" "dev" "qa" "staging" "sandbox")

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
    local valid=0
    echo -e "\n=== Validating Branch to Environment Mapping ==="
    printf "%-10s %-15s %-10s\n" "Branch" "Environment" "Status"
    echo "----------------------------------------"
    
    for branch in "${VALID_BRANCHES[@]}"; do
        local env
        env=$(get_env_from_branch "$branch")
        if [ -z "$env" ]; then
            printf "%-10s %-15s %-10s\n" "$branch" "INVALID" "❌"
            valid=1
        else
            printf "%-10s %-15s %-10s\n" "$branch" "$env" "✅"
        fi
    done
    echo "=========================================="
    return $valid
}

# Create OIDC provider if it doesn't exist
echo -e "\n=== Setting up OIDC Provider ==="
if ! aws iam get-open-id-connect-provider --open-id-connect-provider-arn "arn:aws:iam::${AWS_ACCOUNT_ID}:oidc-provider/token.actions.githubusercontent.com" &> /dev/null; then
    echo "Creating OIDC provider..."
    aws iam create-open-id-connect-provider \
        --url "https://token.actions.githubusercontent.com" \
        --client-id-list "sts.amazonaws.com" \
        --thumbprint-list "6938fd4d98bab03faadb97b34396831e3780aea1"
    
    if [ $? -eq 0 ]; then
        echo "✅ OIDC provider created successfully"
    else
        echo "❌ Error: Failed to create OIDC provider"
        exit 1
    fi
else
    echo "✅ OIDC provider already exists"
fi

# Function to create IAM role for an environment
create_environment_role() {
    local branch=$1
    local env
    local role_name
    
    env=$(get_env_from_branch "$branch")
    if [ -z "$env" ]; then
        echo "❌ Error: Invalid branch name: $branch"
        return 1
    fi
    
    role_name="github-actions-${env}"
    
    echo -e "\n=== Creating IAM Role for $branch ==="
    echo "Branch: $branch"
    echo "Environment: $env"
    echo "Role Name: $role_name"
    
    # Create trust policy
    cat > trust-policy.json << EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Federated": "arn:aws:iam::${AWS_ACCOUNT_ID}:oidc-provider/token.actions.githubusercontent.com"
            },
            "Action": "sts:AssumeRoleWithWebIdentity",
            "Condition": {
                "StringLike": {
                    "token.actions.githubusercontent.com:sub": "repo:${REPO_ORG}/${REPO_NAME}:environment:${env}"
                }
            }
        }
    ]
}
EOF

    # Create role
    if ! aws iam get-role --role-name "$role_name" &> /dev/null; then
        echo "Creating new IAM role: $role_name"
        aws iam create-role \
            --role-name "$role_name" \
            --assume-role-policy-document file://trust-policy.json
        
        if [ $? -eq 0 ]; then
            echo "✅ Role created successfully"
        else
            echo "❌ Error: Failed to create role"
            rm trust-policy.json
            return 1
        fi
    else
        echo "Updating existing role: $role_name"
        aws iam update-assume-role-policy \
            --role-name "$role_name" \
            --policy-document file://trust-policy.json
        echo "✅ Trust policy updated successfully"
    fi

    # Attach policies
    echo "Attaching AdministratorAccess policy to role: $role_name"
    aws iam attach-role-policy \
        --role-name "$role_name" \
        --policy-arn "arn:aws:iam::aws:policy/AdministratorAccess"
    echo "✅ Policy attached successfully"

    # Clean up
    rm trust-policy.json
    echo "=== Role setup completed for $branch ==="
}

# Validate environments
if ! validate_environments; then
    echo -e "\n❌ Error: Environment validation failed"
    exit 1
fi

# Create roles for each environment
echo -e "\n=== Creating IAM Roles ==="
for branch in "${VALID_BRANCHES[@]}"; do
    if ! create_environment_role "$branch"; then
        echo -e "\n❌ Error: Failed to create role for branch: $branch"
        exit 1
    fi
done

echo -e "\n✅ AWS OIDC setup completed successfully!"
echo "The following roles have been created/updated:"
for branch in "${VALID_BRANCHES[@]}"; do
    env=$(get_env_from_branch "$branch")
    echo "- github-actions-${env} (for $branch branch)"
done 