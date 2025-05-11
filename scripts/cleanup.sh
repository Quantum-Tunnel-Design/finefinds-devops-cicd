#!/bin/bash

# Set variables
ENVIRONMENT="dev"
REGION="us-east-1"
TIMESTAMP=$(date +%Y%m%d%H%M%S)

echo "Starting cleanup process..."

# Function to generate RDS-compatible password
generate_rds_password() {
    # Generate a password that meets RDS requirements:
    # - Only printable ASCII characters
    # - No '/', '@', '"', or spaces
    # - At least 8 characters
    openssl rand -base64 32 | tr -dc 'a-zA-Z0-9!$%^&*()_+-=[]{}|;:,.<>?' | head -c 16
}

# Delete existing IAM roles
echo "Deleting existing IAM roles..."
for role in \
    "finefindslk-dev-ecs-execution-role" \
    "finefindslk-dev-grafana" \
    "finefindslk-dev-sonarqube-execution-role" \
    "finefindslk-dev-ecs-task-role" \
    "finefindslk-dev-mongodb-execution-role" \
    "finefindslk-dev-mongodb-task-role" \
    "finefindslk-dev-sonarqube-task-role"
do
    echo "Deleting IAM role: $role"
    aws iam delete-role --role-name "$role" || true
done

# Delete subnet groups
echo "Deleting subnet groups..."
aws rds delete-db-subnet-group --db-subnet-group-name "finefindslk-dev-db-subnet-group" || true
aws docdb delete-db-subnet-group --db-subnet-group-name "finefindslk-dev-docdb-subnet-group" || true

# Delete EFS file system
echo "Deleting EFS file system..."
EFS_ID=$(aws efs describe-file-systems --query "FileSystems[?Name=='sonarqube-dev'].FileSystemId" --output text)
if [ ! -z "$EFS_ID" ]; then
    echo "Deleting EFS file system: $EFS_ID"
    aws efs delete-file-system --file-system-id "$EFS_ID" || true
fi

# Create new secrets with RDS-compatible passwords
echo "Creating new secrets..."
DB_PASSWORD=$(generate_rds_password)
SONARQUBE_DB_PASSWORD=$(generate_rds_password)
JWT_SECRET=$(openssl rand -base64 32)

# Remove any existing secrets with the same names
for secret in \
    "finefindslk-dev-db-password" \
    "finefindslk-dev-sonarqube-password" \
    "finefindslk-dev-jwt-secret"
do
    echo "Removing existing secret: $secret"
    aws secretsmanager delete-secret --secret-id "$secret" --force-delete-without-recovery --region "$REGION" || true
done

# Create new secrets with timestamp
aws secretsmanager create-secret \
    --name "finefindslk-${ENVIRONMENT}-db-password-${TIMESTAMP}" \
    --description "Database password for ${ENVIRONMENT} environment" \
    --secret-string "$DB_PASSWORD" \
    --region "$REGION"

aws secretsmanager create-secret \
    --name "finefindslk-${ENVIRONMENT}-sonarqube-password-${TIMESTAMP}" \
    --description "SonarQube database password for ${ENVIRONMENT} environment" \
    --secret-string "$SONARQUBE_DB_PASSWORD" \
    --region "$REGION"

aws secretsmanager create-secret \
    --name "finefindslk-${ENVIRONMENT}-jwt-secret-${TIMESTAMP}" \
    --description "JWT signing secret for ${ENVIRONMENT} environment" \
    --secret-string "$JWT_SECRET" \
    --region "$REGION"

echo "Cleanup completed!"
echo "Please save these values securely:"
echo "DB_PASSWORD: $DB_PASSWORD"
echo "SONARQUBE_DB_PASSWORD: $SONARQUBE_DB_PASSWORD"
echo "JWT_SECRET: $JWT_SECRET"

# Print the new secret names for reference
echo -e "\nNew secret names:"
echo "Database: finefindslk-${ENVIRONMENT}-db-password-${TIMESTAMP}"
echo "SonarQube: finefindslk-${ENVIRONMENT}-sonarqube-password-${TIMESTAMP}"
echo "JWT: finefindslk-${ENVIRONMENT}-jwt-secret-${TIMESTAMP}"

echo -e "\nNote: You'll need to update your Terraform configuration to use these new secret names."
echo "The passwords have been generated to be compatible with RDS requirements." 