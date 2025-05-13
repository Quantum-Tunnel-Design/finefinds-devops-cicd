#!/bin/bash

# Source environment variables
source ./scripts/export-env.sh

# Function to update trust policy for a role
update_trust_policy() {
    local env=$1
    local role_name="github-actions-${env}"
    
    echo "Updating trust policy for ${role_name}..."
    
    # Create trust policy document
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
                "StringEquals": {
                    "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
                },
                "StringLike": {
                    "token.actions.githubusercontent.com:sub": "repo:${REPO_ORG}/${REPO_NAME}:environment:${env}"
                }
            }
        }
    ]
}
EOF

    # Update the role's trust policy
    aws iam update-assume-role-policy \
        --role-name "${role_name}" \
        --policy-document file://trust-policy.json

    # Clean up
    rm trust-policy.json
    
    echo "✅ Updated trust policy for ${role_name}"
}

# Update trust policies for all environments
echo "Updating trust policies for all roles..."
update_trust_policy "prod"
update_trust_policy "staging"
update_trust_policy "dev"
update_trust_policy "qa"
update_trust_policy "sandbox"

echo "✅ All trust policies have been updated!" 