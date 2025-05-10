#!/bin/bash

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
    echo "AWS CLI is not installed. Please install it first."
    exit 1
fi

# Check if required environment variables are set
if [ -z "$AWS_REGION" ] || [ -z "$ENVIRONMENT" ]; then
    echo "Please set AWS_REGION and ENVIRONMENT environment variables"
    exit 1
fi

# Generate secure passwords if not provided
DB_PASSWORD=${DB_PASSWORD:-$(openssl rand -base64 32)}
SONARQUBE_DB_PASSWORD=${SONARQUBE_DB_PASSWORD:-$(openssl rand -base64 32)}
JWT_SECRET=${JWT_SECRET:-$(openssl rand -base64 32)}

# Create secrets in AWS Secrets Manager
echo "Creating secrets in AWS Secrets Manager..."

# Database password
aws secretsmanager create-secret \
    --name "finefinds/${ENVIRONMENT}/db-password" \
    --description "Database password for ${ENVIRONMENT} environment" \
    --secret-string "$DB_PASSWORD" \
    --region "$AWS_REGION"

# SonarQube database password
aws secretsmanager create-secret \
    --name "finefinds/${ENVIRONMENT}/sonarqube-db-password" \
    --description "SonarQube database password for ${ENVIRONMENT} environment" \
    --secret-string "$SONARQUBE_DB_PASSWORD" \
    --region "$AWS_REGION"

# JWT secret
aws secretsmanager create-secret \
    --name "finefinds/${ENVIRONMENT}/jwt-secret" \
    --description "JWT signing secret for ${ENVIRONMENT} environment" \
    --secret-string "$JWT_SECRET" \
    --region "$AWS_REGION"

echo "Secrets created successfully!"
echo "Please save these values securely:"
echo "DB_PASSWORD: $DB_PASSWORD"
echo "SONARQUBE_DB_PASSWORD: $SONARQUBE_DB_PASSWORD"
echo "JWT_SECRET: $JWT_SECRET" 