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
    "finefinds-dev-ecs-execution-role" \
    "finefinds-dev-grafana" \
    "finefinds-dev-sonarqube-execution-role" \
    "finefinds-dev-ecs-task-role" \
    "finefinds-dev-mongodb-execution-role" \
    "finefinds-dev-mongodb-task-role" \
    "finefinds-dev-sonarqube-task-role"
do
    echo "Deleting IAM role: $role"
    aws iam delete-role --role-name "$role" || true
done

# Delete subnet groups
echo "Deleting subnet groups..."
aws rds delete-db-subnet-group --db-subnet-group-name "finefinds-dev-db-subnet-group" || true
aws docdb delete-db-subnet-group --db-subnet-group-name "finefinds-dev-docdb-subnet-group" || true

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
    "finefinds-dev-db-password" \
    "finefinds-dev-sonarqube-password" \
    "finefinds-dev-jwt-secret"
do
    echo "Removing existing secret: $secret"
    aws secretsmanager delete-secret --secret-id "$secret" --force-delete-without-recovery --region "$REGION" || true
done

# Create new secrets with timestamp
aws secretsmanager create-secret \
    --name "finefinds-${ENVIRONMENT}-db-password-${TIMESTAMP}" \
    --description "Database password for ${ENVIRONMENT} environment" \
    --secret-string "$DB_PASSWORD" \
    --region "$REGION"

aws secretsmanager create-secret \
    --name "finefinds-${ENVIRONMENT}-sonarqube-password-${TIMESTAMP}" \
    --description "SonarQube database password for ${ENVIRONMENT} environment" \
    --secret-string "$SONARQUBE_DB_PASSWORD" \
    --region "$REGION"

aws secretsmanager create-secret \
    --name "finefinds-${ENVIRONMENT}-jwt-secret-${TIMESTAMP}" \
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
echo "Database: finefinds-${ENVIRONMENT}-db-password-${TIMESTAMP}"
echo "SonarQube: finefinds-${ENVIRONMENT}-sonarqube-password-${TIMESTAMP}"
echo "JWT: finefinds-${ENVIRONMENT}-jwt-secret-${TIMESTAMP}"

echo -e "\nNote: You'll need to update your Terraform configuration to use these new secret names."
echo "The passwords have been generated to be compatible with RDS requirements." 