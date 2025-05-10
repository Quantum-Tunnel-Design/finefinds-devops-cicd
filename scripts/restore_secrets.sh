#!/bin/bash

# Set variables
ENVIRONMENT="dev"
REGION="us-east-1"
TIMESTAMP=$(date +%Y%m%d%H%M%S)

# Generate secure passwords
DB_PASSWORD=$(openssl rand -base64 32)
SONARQUBE_DB_PASSWORD=$(openssl rand -base64 32)
JWT_SECRET=$(openssl rand -base64 32)

echo "Creating new secrets in AWS Secrets Manager..."

# Database password
aws secretsmanager create-secret \
    --name "finefinds-${ENVIRONMENT}-db-password-${TIMESTAMP}" \
    --description "Database password for ${ENVIRONMENT} environment" \
    --secret-string "$DB_PASSWORD" \
    --region "$REGION"

# SonarQube database password
aws secretsmanager create-secret \
    --name "finefinds-${ENVIRONMENT}-sonarqube-password-${TIMESTAMP}" \
    --description "SonarQube database password for ${ENVIRONMENT} environment" \
    --secret-string "$SONARQUBE_DB_PASSWORD" \
    --region "$REGION"

# JWT secret
aws secretsmanager create-secret \
    --name "finefinds-${ENVIRONMENT}-jwt-secret-${TIMESTAMP}" \
    --description "JWT signing secret for ${ENVIRONMENT} environment" \
    --secret-string "$JWT_SECRET" \
    --region "$REGION"

echo "Secrets created successfully!"
echo "Please save these values securely:"
echo "DB_PASSWORD: $DB_PASSWORD"
echo "SONARQUBE_DB_PASSWORD: $SONARQUBE_DB_PASSWORD"
echo "JWT_SECRET: $JWT_SECRET"

# Print the new secret names for reference
echo -e "\nNew secret names:"
echo "Database: finefinds-${ENVIRONMENT}-db-password-${TIMESTAMP}"
echo "SonarQube: finefinds-${ENVIRONMENT}-sonarqube-password-${TIMESTAMP}"
echo "JWT: finefinds-${ENVIRONMENT}-jwt-secret-${TIMESTAMP}" 