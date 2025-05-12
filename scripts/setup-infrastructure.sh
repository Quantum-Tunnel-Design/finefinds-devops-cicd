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
PROJECT_NAME="finefindslk" # Added for consistency
DB_USER_FOR_SECRET="ffadmin" # Align with generate-secrets.sh

# Create S3 bucket for Terraform state
print_message "Creating S3 bucket for Terraform state (${PROJECT_NAME}-terraform-state-${ENVIRONMENT})..." "$YELLOW"
aws s3api create-bucket \
    --bucket "${PROJECT_NAME}-terraform-state-${ENVIRONMENT}" \
    --region $REGION

# Enable versioning
aws s3api put-bucket-versioning \
    --bucket "${PROJECT_NAME}-terraform-state-${ENVIRONMENT}" \
    --versioning-configuration Status=Enabled

# Enable encryption
aws s3api put-bucket-encryption \
    --bucket "${PROJECT_NAME}-terraform-state-${ENVIRONMENT}" \
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
print_message "Creating DynamoDB table for state locking (${PROJECT_NAME}-terraform-locks-${ENVIRONMENT})..." "$YELLOW"
aws dynamodb create-table \
    --table-name "${PROJECT_NAME}-terraform-locks-${ENVIRONMENT}" \
    --attribute-definitions AttributeName=LockID,AttributeType=S \
    --key-schema AttributeName=LockID,KeyType=HASH \
    --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5

# Create backend configuration
print_message "Creating backend configuration (terraform/environments/${ENVIRONMENT}/backend.tf)..." "$YELLOW"
cat > terraform/environments/${ENVIRONMENT}/backend.tf << EOL
terraform {
  backend "s3" {
    bucket         = "${PROJECT_NAME}-terraform-state-${ENVIRONMENT}"
    key            = "terraform.tfstate"
    region         = "${REGION}"
    dynamodb_table = "${PROJECT_NAME}-terraform-locks-${ENVIRONMENT}"
    encrypt        = true
  }
}
EOL

# Create terraform.tfvars
print_message "Creating terraform.tfvars (terraform/environments/${ENVIRONMENT}/terraform.tfvars)..." "$YELLOW"
cat > terraform/environments/${ENVIRONMENT}/terraform.tfvars << EOL
project     = "${PROJECT_NAME}"
environment = "${ENVIRONMENT}"
aws_region  = "${REGION}"

# Database configuration
# db_password is now managed by generate-secrets.sh and AWS Secrets Manager.
# db_username set here should be the master username for RDS instance creation.
# The username stored in the secret (by generate-secrets.sh) will be used by the application.
# Ensure these are consistent or that the application uses the secret's username.
db_username = "${DB_USER_FOR_SECRET}" # Aligning with what generate-secrets.sh uses for the secret

# Container configuration
container_name = "app"
container_port = 3000
image_tag      = "latest"

# Alert configuration
alert_email = "amal.c.gamage@gmail.com"  # Change this to your email
EOL

print_message "Infrastructure setup script completed for ${ENVIRONMENT}!" "$GREEN"
print_message "Next steps:" "$YELLOW"
echo "1. Review terraform/environments/${ENVIRONMENT}/terraform.tfvars and update placeholders if any (e.g., alert_email)."
echo "2. Ensure your AWS credentials are configured correctly for Terraform."
echo "3. Run scripts/generate-secrets.sh ${ENVIRONMENT} to create necessary secrets."
echo "4. Initialize Terraform:"
echo "   cd terraform/environments/${ENVIRONMENT}"
echo "   terraform init"
echo "5. Review the plan:"
echo "   terraform plan"
# Remind user about providing essential variables like repository URLs for plan/apply if not in tfvars
echo "   (You might need to provide -var for client_repository, admin_repository, source_token if running plan/apply locally and they are not in tfvars or secrets)"
echo "6. Apply the configuration:"
echo "   terraform apply" 