#!/bin/bash

# === Colors ===
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_message() {
    echo -e "${2}${1}${NC}"
}

# === Validate CLI Requirements ===
if ! command -v aws &> /dev/null; then
  print_message "Error: AWS CLI not installed." "$RED"
  exit 1
fi

if ! aws sts get-caller-identity &> /dev/null; then
  print_message "Error: AWS credentials not configured." "$RED"
  exit 1
fi

# === Parse Inputs ===
if [ -z "$1" ]; then
    print_message "Error: Environment not provided" "$RED"
    echo "Usage: $0 <environment>"
    exit 1
fi

ENVIRONMENT=$1
REGION="us-east-1"
PROJECT_NAME="finefindslk"
DB_USER_FOR_SECRET="ffadmin"
STATE_BUCKET="${PROJECT_NAME}-terraform-state-${ENVIRONMENT}"
LOCK_TABLE="${PROJECT_NAME}-terraform-locks-${ENVIRONMENT}"

# === Check/Create S3 Bucket ===
print_message "Checking for existing S3 bucket: $STATE_BUCKET" "$YELLOW"
if aws s3api head-bucket --bucket "$STATE_BUCKET" 2>/dev/null; then
  print_message "S3 bucket already exists. Skipping creation." "$GREEN"
else
  print_message "Creating S3 bucket: $STATE_BUCKET" "$YELLOW"
  aws s3api create-bucket \
    --bucket "$STATE_BUCKET" \
    --region $REGION \
    --create-bucket-configuration LocationConstraint=$REGION

  print_message "Enabling versioning on bucket..." "$YELLOW"
  aws s3api put-bucket-versioning \
    --bucket "$STATE_BUCKET" \
    --versioning-configuration Status=Enabled

  print_message "Enabling encryption on bucket..." "$YELLOW"
  aws s3api put-bucket-encryption \
    --bucket "$STATE_BUCKET" \
    --server-side-encryption-configuration '{
      "Rules": [{
        "ApplyServerSideEncryptionByDefault": {
          "SSEAlgorithm": "AES256"
        }
      }]
    }'
fi

# === Check/Create DynamoDB Table ===
print_message "Checking for existing DynamoDB lock table: $LOCK_TABLE" "$YELLOW"
if aws dynamodb describe-table --table-name "$LOCK_TABLE" 2>/dev/null; then
  print_message "DynamoDB lock table already exists. Skipping creation." "$GREEN"
else
  print_message "Creating DynamoDB lock table: $LOCK_TABLE" "$YELLOW"
  aws dynamodb create-table \
    --table-name "$LOCK_TABLE" \
    --attribute-definitions AttributeName=LockID,AttributeType=S \
    --key-schema AttributeName=LockID,KeyType=HASH \
    --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5
fi

# === Write backend.tf ===
print_message "Writing backend.tf..." "$YELLOW"
BACKEND_PATH="terraform/environments/${ENVIRONMENT}/backend.tf"
mkdir -p "$(dirname "$BACKEND_PATH")"

cat > "$BACKEND_PATH" << EOL
terraform {
  backend "s3" {
    bucket         = "$STATE_BUCKET"
    key            = "terraform.tfstate"
    region         = "$REGION"
    dynamodb_table = "$LOCK_TABLE"
    encrypt        = true
  }
}
EOL

# === Write terraform.tfvars ===
print_message "Writing terraform.tfvars..." "$YELLOW"
cat > terraform/environments/${ENVIRONMENT}/terraform.tfvars << EOL
project     = "$PROJECT_NAME"
environment = "$ENVIRONMENT"
aws_region  = "$REGION"

db_username = "$DB_USER_FOR_SECRET"

container_name = "app"
container_port = 3000
image_tag      = "latest"

alert_email = "amal.c.gamage@gmail.com"
EOL

# === Completion Message ===
print_message "✅ Infrastructure setup complete for '$ENVIRONMENT'" "$GREEN"