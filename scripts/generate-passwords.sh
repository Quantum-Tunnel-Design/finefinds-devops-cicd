#!/bin/bash

# Function to check if a secret exists
check_secret_exists() {
    local secret_name=$1
    aws secretsmanager describe-secret --secret-id "finefinds/${ENVIRONMENT}/${secret_name}" >/dev/null 2>&1
    return $?
}

# Function to check if a secret is scheduled for deletion
check_secret_scheduled_for_deletion() {
    local secret_name=$1
    aws secretsmanager describe-secret --secret-id "finefinds/${ENVIRONMENT}/${secret_name}" | grep -q "DeletedDate"
    return $?
}

# Function to restore a deleted secret
restore_secret() {
    local secret_name=$1
    aws secretsmanager restore-secret --secret-id "finefinds/${ENVIRONMENT}/${secret_name}"
    echo "Restored secret: ${secret_name}"
}

# Function to generate and store a password
generate_and_store_password() {
    local secret_name=$1
    local description=$2
    local full_secret_name="finefinds/${ENVIRONMENT}/${secret_name}"
    
    # Check if secret exists
    if check_secret_exists "$secret_name"; then
        echo "Secret ${secret_name} already exists, skipping..."
        return
    fi
    
    # Check if secret is scheduled for deletion
    if check_secret_scheduled_for_deletion "$secret_name"; then
        echo "Secret ${secret_name} is scheduled for deletion, restoring..."
        restore_secret "$secret_name"
        return
    fi
    
    # Generate a secure random password using OpenSSL
    PASSWORD=$(openssl rand -base64 32)
    
    # Store the password in AWS Secrets Manager
    aws secretsmanager create-secret \
        --name "$full_secret_name" \
        --description "${description} for ${ENVIRONMENT} environment" \
        --secret-string "$PASSWORD" \
        --tags Key=Environment,Value=${ENVIRONMENT} Key=Project,Value=finefinds
    
    if [ $? -eq 0 ]; then
        echo "${secret_name} password has been generated and stored in AWS Secrets Manager"
    else
        echo "Error: Failed to create secret ${secret_name}"
        return 1
    fi
}

# Check if ENVIRONMENT is set
if [ -z "$ENVIRONMENT" ]; then
    echo "Error: ENVIRONMENT variable is not set"
    echo "Usage: ENVIRONMENT=<env> ./scripts/generate-passwords.sh"
    exit 1
fi

# Check if AWS CLI is configured
if ! aws sts get-caller-identity >/dev/null 2>&1; then
    echo "Error: AWS CLI is not configured properly"
    echo "Please run 'aws configure' first"
    exit 1
fi

# Generate and store all passwords
echo "Generating passwords for ${ENVIRONMENT} environment..."
generate_and_store_password "db-password" "Main database"
generate_and_store_password "mongodb-password" "MongoDB"
generate_and_store_password "sonarqube-password" "SonarQube database"

echo "Password generation completed" 