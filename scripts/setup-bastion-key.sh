#!/bin/bash

# Get environment from argument or use 'dev' as default
ENVIRONMENT=${1:-dev}
KEY_NAME="finefinds-${ENVIRONMENT}-bastion"
KEY_FILE="${KEY_NAME}.pem"

# Check if key pair exists in AWS
if aws ec2 describe-key-pairs --key-names "$KEY_NAME" 2>/dev/null; then
    echo "Key pair $KEY_NAME exists in AWS, downloading..."
    # Delete existing key file if it exists
    rm -f "$KEY_FILE"
    # Download the key
    aws ec2 create-key-pair \
        --key-name "$KEY_NAME" \
        --query 'KeyMaterial' \
        --output text > "$KEY_FILE"
else
    echo "Creating key pair $KEY_NAME..."
    aws ec2 create-key-pair \
        --key-name "$KEY_NAME" \
        --query 'KeyMaterial' \
        --output text > "$KEY_FILE"
fi

# Set proper permissions for the key file
chmod 400 "$KEY_FILE"

# Add tags to the key pair
aws ec2 create-tags \
    --resources "$KEY_NAME" \
    --tags "Key=Environment,Value=$ENVIRONMENT" "Key=Project,Value=FineFinds"

echo "Key pair created and saved to $KEY_FILE"

# Add key file to .gitignore if not already there
if ! grep -q "$KEY_FILE" .gitignore; then
    echo "$KEY_FILE" >> .gitignore
    echo "Added $KEY_FILE to .gitignore"
fi

echo "Bastion key pair setup complete" 