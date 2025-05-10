#!/bin/bash

# Function to create IAM role
create_iam_role() {
  local role_name="github-actions-${ENV_NAME}"
  
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
                "StringEquals": {
                    "token.actions.githubusercontent.com:aud": "sts.amazonaws.com",
                    "token.actions.githubusercontent.com:sub": "repo:${GITHUB_REPOSITORY}:environment:${ENV_NAME}"
                }
            }
        }
    ]
}
EOF
  
  # Create or update role
  if ! aws iam get-role --role-name "$role_name" &> /dev/null; then
    aws iam create-role \
      --role-name "$role_name" \
      --assume-role-policy-document file://trust-policy.json
    
    if [ $? -eq 0 ]; then
      echo "✅ Role created successfully"
    else
      echo "❌ Failed to create role"
      rm trust-policy.json
      return 1
    fi
  else
    aws iam update-assume-role-policy \
      --role-name "$role_name" \
      --policy-document file://trust-policy.json
    
    if [ $? -eq 0 ]; then
      echo "✅ Role trust policy updated successfully"
    else
      echo "❌ Failed to update role trust policy"
      rm trust-policy.json
      return 1
    fi
  fi
  
  # Attach AdministratorAccess policy
  echo "Attaching AdministratorAccess policy..."
  aws iam attach-role-policy \
    --role-name "$role_name" \
    --policy-arn "arn:aws:iam::aws:policy/AdministratorAccess"
  
  if [ $? -eq 0 ]; then
    echo "✅ Policy attached successfully"
  else
    echo "❌ Failed to attach policy"
    rm trust-policy.json
    return 1
  fi
  
  rm trust-policy.json
  return 0
}

# Main script
echo "=== Verifying OIDC Configuration ==="

# Check if OIDC provider exists
echo "Checking OIDC provider..."
if ! aws iam get-open-id-connect-provider --open-id-connect-provider-arn "arn:aws:iam::${AWS_ACCOUNT_ID}:oidc-provider/token.actions.githubusercontent.com" &> /dev/null; then
  echo "❌ OIDC provider not found"
  echo "Attempting to create OIDC provider..."
  aws iam create-open-id-connect-provider \
    --url "https://token.actions.githubusercontent.com" \
    --client-id-list "sts.amazonaws.com" \
    --thumbprint-list "6938fd4d98bab03faadb97b34396831e3780aea1"
  
  if [ $? -eq 0 ]; then
    echo "✅ OIDC provider created successfully"
  else
    echo "❌ Failed to create OIDC provider"
    exit 1
  fi
else
  echo "✅ OIDC provider exists"
fi

# Check if IAM role exists
echo "Checking IAM role..."
if ! aws iam get-role --role-name "github-actions-${ENV_NAME}" &> /dev/null; then
  echo "❌ IAM role 'github-actions-${ENV_NAME}' not found"
  echo "Attempting to create IAM role..."
  if ! create_iam_role; then
    exit 1
  fi
else
  echo "✅ IAM role exists"
  
  # Verify trust policy
  echo "Verifying trust policy..."
  TRUST_POLICY=$(aws iam get-role --role-name "github-actions-${ENV_NAME}" --query 'Role.AssumeRolePolicyDocument' --output json)
  
  # Check if the trust policy needs updating
  NEEDS_UPDATE=false
  
  if ! echo "$TRUST_POLICY" | grep -q "token.actions.githubusercontent.com"; then
    echo "⚠️ Trust policy has incorrect OIDC provider"
    NEEDS_UPDATE=true
  fi
  
  if ! echo "$TRUST_POLICY" | grep -q "repo:${GITHUB_REPOSITORY}:environment:${ENV_NAME}"; then
    echo "⚠️ Trust policy has incorrect repository or environment"
    NEEDS_UPDATE=true
  fi
  
  if [ "$NEEDS_UPDATE" = true ]; then
    echo "Attempting to update trust policy..."
    if ! create_iam_role; then
      exit 1
    fi
  else
    echo "✅ Trust policy is correctly configured"
  fi
fi

echo "=== OIDC Configuration Verification Complete ===" 