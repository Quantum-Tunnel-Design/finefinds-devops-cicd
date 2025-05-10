#!/bin/bash

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
    echo "AWS CLI is not installed. Please install it first."
    exit 1
fi

# Check if required environment variables are set
if [ -z "$AWS_ACCOUNT_ID" ] || [ -z "$GITHUB_ORG" ] || [ -z "$GITHUB_REPO" ]; then
    echo "Please set AWS_ACCOUNT_ID, GITHUB_ORG, and GITHUB_REPO environment variables"
    exit 1
fi

# Create OIDC provider if it doesn't exist
aws iam get-open-id-connect-provider --open-id-connect-provider-arn "arn:aws:iam::${AWS_ACCOUNT_ID}:oidc-provider/token.actions.githubusercontent.com" || \
aws iam create-open-id-connect-provider \
    --url "https://token.actions.githubusercontent.com" \
    --client-id-list "sts.amazonaws.com" \
    --thumbprint-list "6938fd4d98bab03faadb97b34396831e3780aea1"

# Function to create IAM role for an environment
create_environment_role() {
    local env=$1
    local role_name="github-actions-${env}"
    
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
                    "token.actions.githubusercontent.com:sub": "repo:${GITHUB_ORG}/${GITHUB_REPO}:environment:${env}"
                }
            }
        }
    ]
}
EOF

    # Create role
    aws iam create-role \
        --role-name "$role_name" \
        --assume-role-policy-document file://trust-policy.json

    # Attach policies
    aws iam attach-role-policy \
        --role-name "$role_name" \
        --policy-arn "arn:aws:iam::aws:policy/AdministratorAccess"

    # Clean up
    rm trust-policy.json
}

# Create roles for each environment
for env in main dev qa staging sandbox; do
    echo "Creating IAM role for environment: $env"
    create_environment_role "$env"
done

echo "AWS OIDC setup completed!" 