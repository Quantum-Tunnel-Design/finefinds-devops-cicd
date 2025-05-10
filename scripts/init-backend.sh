#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Function to print colored messages
print_message() {
    echo -e "${2}${1}${NC}"
}

# Check if environment is provided
if [ -z "$1" ]; then
    print_message "Error: Environment not provided" "$RED"
    echo "Usage: $0 <environment>"
    echo "Environments: sandbox, qa, dev, staging, prod"
    exit 1
fi

ENVIRONMENT=$1
REGION="us-east-1"

# Determine account type and bucket name
if [ "$ENVIRONMENT" == "prod" ]; then
    ACCOUNT_TYPE="prod"
    BUCKET_NAME="finefinds-terraform-state-prod"
    PROFILE="prod"
else
    ACCOUNT_TYPE="nonprod"
    BUCKET_NAME="finefinds-terraform-state-nonprod"
    PROFILE="nonprod"
fi

# Create S3 bucket if it doesn't exist
if ! aws s3api head-bucket --bucket $BUCKET_NAME --profile $PROFILE 2>/dev/null; then
    print_message "Creating S3 bucket for Terraform state..." "$YELLOW"
    aws s3api create-bucket \
        --bucket $BUCKET_NAME \
        --region $REGION \
        --profile $PROFILE

    # Enable versioning
    aws s3api put-bucket-versioning \
        --bucket $BUCKET_NAME \
        --versioning-configuration Status=Enabled \
        --profile $PROFILE

    # Enable encryption
    aws s3api put-bucket-encryption \
        --bucket $BUCKET_NAME \
        --server-side-encryption-configuration '{
            "Rules": [
                {
                    "ApplyServerSideEncryptionByDefault": {
                        "SSEAlgorithm": "AES256"
                    }
                }
            ]
        }' \
        --profile $PROFILE
fi

# Create DynamoDB table if it doesn't exist
if ! aws dynamodb describe-table --table-name finefinds-terraform-locks --profile $PROFILE 2>/dev/null; then
    print_message "Creating DynamoDB table for state locking..." "$YELLOW"
    aws dynamodb create-table \
        --table-name finefinds-terraform-locks \
        --attribute-definitions AttributeName=LockID,AttributeType=S \
        --key-schema AttributeName=LockID,KeyType=HASH \
        --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5 \
        --profile $PROFILE
fi

# Initialize Terraform
print_message "Initializing Terraform for $ENVIRONMENT environment..." "$YELLOW"
cd terraform/environments/$ENVIRONMENT

terraform init \
    -backend-config="bucket=$BUCKET_NAME" \
    -backend-config="key=$ENVIRONMENT/terraform.tfstate" \
    -backend-config="region=$REGION" \
    -backend-config="dynamodb_table=finefinds-terraform-locks" \
    -backend-config="encrypt=true"

if [ $? -eq 0 ]; then
    print_message "Terraform initialized successfully for $ENVIRONMENT environment!" "$GREEN"
else
    print_message "Error initializing Terraform for $ENVIRONMENT environment" "$RED"
    exit 1
fi 