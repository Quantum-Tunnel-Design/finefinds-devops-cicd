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
    echo "Environments: dev, staging, prod"
    exit 1
fi

ENVIRONMENT=$1
REGION="us-east-1"

# Create S3 bucket for Terraform state
print_message "Creating S3 bucket for Terraform state..." "$YELLOW"
aws s3api create-bucket \
    --bucket "finefinds-terraform-state-${ENVIRONMENT}" \
    --region $REGION

# Enable versioning
aws s3api put-bucket-versioning \
    --bucket "finefinds-terraform-state-${ENVIRONMENT}" \
    --versioning-configuration Status=Enabled

# Enable encryption
aws s3api put-bucket-encryption \
    --bucket "finefinds-terraform-state-${ENVIRONMENT}" \
    --server-side-encryption-configuration '{
        "Rules": [
            {
                "ApplyServerSideEncryptionByDefault": {
                    "SSEAlgorithm": "AES256"
                }
            }
        ]
    }'

# Create DynamoDB table for state locking
print_message "Creating DynamoDB table for state locking..." "$YELLOW"
aws dynamodb create-table \
    --table-name "finefinds-terraform-locks" \
    --attribute-definitions AttributeName=LockID,AttributeType=S \
    --key-schema AttributeName=LockID,KeyType=HASH \
    --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5

# Create backend configuration
print_message "Creating backend configuration..." "$YELLOW"
cat > terraform/environments/${ENVIRONMENT}/backend.tf << EOL
terraform {
  backend "s3" {
    bucket         = "finefinds-terraform-state-${ENVIRONMENT}"
    key            = "terraform.tfstate"
    region         = "${REGION}"
    dynamodb_table = "finefinds-terraform-locks"
    encrypt        = true
  }
}
EOL

# Create terraform.tfvars
print_message "Creating terraform.tfvars..." "$YELLOW"
cat > terraform/environments/${ENVIRONMENT}/terraform.tfvars << EOL
project     = "finefinds"
environment = "${ENVIRONMENT}"
aws_region  = "${REGION}"

# Database configuration
db_username = "admin"
db_password = "CHANGE_ME"  # Change this to a secure password

# SonarQube configuration
sonarqube_db_username = "sonarqube"
sonarqube_db_password = "CHANGE_ME"  # Change this to a secure password

# Container configuration
container_name = "app"
container_port = 3000
image_tag      = "latest"

# Alert configuration
alert_email = "amal.c.gamage@gmail.com"  # Change this to your email
EOL

print_message "Infrastructure setup completed!" "$GREEN"
print_message "Next steps:" "$YELLOW"
echo "1. Update terraform.tfvars with secure passwords and your email"
echo "2. Initialize Terraform:"
echo "   cd terraform/environments/${ENVIRONMENT}"
echo "   terraform init"
echo "3. Review the plan:"
echo "   terraform plan"
echo "4. Apply the configuration:"
echo "   terraform apply" 