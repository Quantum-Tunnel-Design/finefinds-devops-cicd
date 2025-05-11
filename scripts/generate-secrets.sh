#!/bin/bash

# Exit on error
set -e

# Function to check if AWS CLI is installed and configured
check_aws_cli() {
    if ! command -v aws &> /dev/null; then
        echo "Error: AWS CLI is not installed"
        exit 1
    fi

    # Check if AWS credentials are configured
    if ! aws sts get-caller-identity &> /dev/null; then
        echo "Error: AWS credentials are not configured"
        exit 1
    fi
}

# Function to validate environment
validate_environment() {
    local env=$1
    if [[ ! "$env" =~ ^(dev|staging|prod)$ ]]; then
        echo "Error: Environment must be one of: dev, staging, prod"
        exit 1
    fi
}

# Function to generate secure random string
generate_secure_string() {
    openssl rand -base64 32 | tr -dc 'a-zA-Z0-9!@#$%^&*()_+' | head -c 32
}

# Function to create or update secret
create_or_update_secret() {
    local name=$1
    local value=$2
    local description=$3
    local region=$4

    # Try to create the secret
    if aws secretsmanager create-secret \
        --name "$name" \
        --description "$description" \
        --secret-string "$value" \
        --region "$region" &> /dev/null; then
        echo "Created secret: $name"
    else
        # If creation fails, update the secret
        aws secretsmanager update-secret \
            --secret-id "$name" \
            --secret-string "$value" \
            --region "$region" &> /dev/null
        echo "Updated secret: $name"
    fi
}

# Function to get secret ARN
get_secret_arn() {
    local name=$1
    local region=$2
    aws secretsmanager describe-secret \
        --secret-id "$name" \
        --query 'ARN' \
        --output text \
        --region "$region"
}

# Main script
main() {
    # Check AWS CLI
    check_aws_cli

    # Set environment variables
    ENVIRONMENT=${1:-dev}
    PROJECT="finefinds"
    REGION="us-east-1"

    # Validate environment
    validate_environment "$ENVIRONMENT"

    # Generate secure random strings for passwords
    echo "Generating secure random strings for passwords..."
    DB_PASSWORD=$(generate_secure_string)
    MONGODB_PASSWORD=$(generate_secure_string)

    # Set manual usernames
    echo "Setting manual usernames..."
    DB_USERNAME="ffadmin"
    MONGODB_USERNAME="ffadminmongo"

    # Set repository URLs
    echo "Setting repository URLs..."
    CLIENT_REPOSITORY="https://github.com/Quantum-Tunnel-Design/finefinds-client-web-app.git"
    ADMIN_REPOSITORY="https://github.com/Quantum-Tunnel-Design/finefinds-admin"

    # Set SonarQube token
    echo "Setting SonarQube token..."
    SONAR_TOKEN="UPDATE_TOKEN"

    # Set GitHub source token
    echo "Setting GitHub source token..."
    SOURCE_TOKEN="UPDATE_TOKEN"

    # Create or update secrets
    echo "Creating/updating secrets in AWS Secrets Manager..."

    # Passwords (automatically generated)
    create_or_update_secret \
        "finefindslk/${ENVIRONMENT}/db-password" \
        "$DB_PASSWORD" \
        "Database password for ${ENVIRONMENT}" \
        "$REGION"

    create_or_update_secret \
        "finefindslk/${ENVIRONMENT}/mongodb-password" \
        "$MONGODB_PASSWORD" \
        "MongoDB password for ${ENVIRONMENT}" \
        "$REGION"

    create_or_update_secret \
        "finefindslk/${ENVIRONMENT}/sonar-token" \
        "$SONAR_TOKEN" \
        "SonarQube token for ${ENVIRONMENT}" \
        "$REGION"

    create_or_update_secret \
        "finefindslk/${ENVIRONMENT}/source-token" \
        "$SOURCE_TOKEN" \
        "GitHub source token for ${ENVIRONMENT}" \
        "$REGION"

    # Usernames (manually set)
    create_or_update_secret \
        "finefindslk/${ENVIRONMENT}/db-username" \
        "$DB_USERNAME" \
        "Database username for ${ENVIRONMENT}" \
        "$REGION"

    create_or_update_secret \
        "finefindslk/${ENVIRONMENT}/mongodb-username" \
        "$MONGODB_USERNAME" \
        "MongoDB username for ${ENVIRONMENT}" \
        "$REGION"

    # Repository URLs (manually set)
    create_or_update_secret \
        "finefindslk/${ENVIRONMENT}/client-repository" \
        "$CLIENT_REPOSITORY" \
        "Client repository URL for ${ENVIRONMENT}" \
        "$REGION"

    create_or_update_secret \
        "finefindslk/${ENVIRONMENT}/admin-repository" \
        "$ADMIN_REPOSITORY" \
        "Admin repository URL for ${ENVIRONMENT}" \
        "$REGION"

    # Get ARNs
    echo "Retrieving secret ARNs..."
    DB_PASSWORD_ARN=$(get_secret_arn "finefindslk/${ENVIRONMENT}/db-password" "$REGION")
    MONGODB_PASSWORD_ARN=$(get_secret_arn "finefindslk/${ENVIRONMENT}/mongodb-password" "$REGION")
    SONAR_TOKEN_ARN=$(get_secret_arn "finefindslk/${ENVIRONMENT}/sonar-token" "$REGION")
    SOURCE_TOKEN_ARN=$(get_secret_arn "finefindslk/${ENVIRONMENT}/source-token" "$REGION")
    DB_USERNAME_ARN=$(get_secret_arn "finefindslk/${ENVIRONMENT}/db-username" "$REGION")
    MONGODB_USERNAME_ARN=$(get_secret_arn "finefindslk/${ENVIRONMENT}/mongodb-username" "$REGION")
    CLIENT_REPOSITORY_ARN=$(get_secret_arn "finefindslk/${ENVIRONMENT}/client-repository" "$REGION")
    ADMIN_REPOSITORY_ARN=$(get_secret_arn "finefindslk/${ENVIRONMENT}/admin-repository" "$REGION")

    # Create tfvars file
    TFVARS_PATH="terraform/environments/${ENVIRONMENT}/secrets.auto.tfvars"
    echo "Creating Terraform variables file at ${TFVARS_PATH}..."
    
    cat > "$TFVARS_PATH" << EOF
# Generated secrets for ${ENVIRONMENT} environment
# DO NOT COMMIT THIS FILE TO VERSION CONTROL
# Generated on: $(date)

# Password ARNs
db_password_arn = "${DB_PASSWORD_ARN}"
mongodb_password_arn = "${MONGODB_PASSWORD_ARN}"
sonar_token_arn = "${SONAR_TOKEN_ARN}"
source_token_arn = "${SOURCE_TOKEN_ARN}"

# Username ARNs
db_username_arn = "${DB_USERNAME_ARN}"
mongodb_username_arn = "${MONGODB_USERNAME_ARN}"

# Repository ARNs
client_repository_arn = "${CLIENT_REPOSITORY_ARN}"
admin_repository_arn = "${ADMIN_REPOSITORY_ARN}"

# Optional: Store actual values for reference (not used by Terraform)
db_username = "${DB_USERNAME}"
db_password = "${DB_PASSWORD}"
mongodb_username = "${MONGODB_USERNAME}"
mongodb_password = "${MONGODB_PASSWORD}"
sonar_token = "${SONAR_TOKEN}"
source_token = "${SOURCE_TOKEN}"
client_repository = "${CLIENT_REPOSITORY}"
admin_repository = "${ADMIN_REPOSITORY}"
EOF

    # Set proper permissions
    chmod 600 "$TFVARS_PATH"

    echo "✅ Secrets generated and stored in AWS Secrets Manager"
    echo "✅ Terraform variables file created at ${TFVARS_PATH}"
    echo "⚠️  DO NOT COMMIT secrets.auto.tfvars TO VERSION CONTROL"
    echo "⚠️  File permissions set to 600 (read/write for owner only)"
}

# Run main function
main "$@" 