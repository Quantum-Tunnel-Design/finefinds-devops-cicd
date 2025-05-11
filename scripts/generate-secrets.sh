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
    PROJECT="finefindslk"
    REGION="us-east-1"

    # Validate environment
    validate_environment "$ENVIRONMENT"

    # Generate secure random strings for passwords
    echo "Generating secure random strings for passwords..."
    JWT_SECRET=$(generate_secure_string)
    DB_PASSWORD=$(generate_secure_string)

    # Set manual usernames
    echo "Setting manual usernames..."
    DB_USERNAME="ffadmin"

    # Set repository URLs
    echo "Setting repository URLs..."
    CLIENT_REPOSITORY="https://github.com/Quantum-Tunnel-Design/finefindslk-client-web-app.git"
    ADMIN_REPOSITORY="https://github.com/Quantum-Tunnel-Design/finefindslk-admin"

    # Set SonarQube token
    echo "Setting SonarQube token..."
    SONAR_TOKEN="UPDATE_TOKEN"

    # Set GitHub source token
    echo "Setting GitHub source token..."
    SOURCE_TOKEN="UPDATE_TOKEN"

    # Create or update secrets
    echo "Creating/updating secrets in AWS Secrets Manager..."

    # Database credentials
    jwt_secret_json=$(printf '{"password":"%s", "database":"finefindslk"}' "$JWT_SECRET")
    create_or_update_secret \
        "finefindslk/${ENVIRONMENT}/jwt-secret" \
        "$jwt_secret_json" \
        "JWT credentials for ${PROJECT} ${ENVIRONMENT}" \
        "$REGION"
    
    db_secret_json=$(printf '{"username":"%s","password":"%s","host":"","port":5432,"database":"finefindslk"}' "$DB_USERNAME" "$DB_PASSWORD")
    create_or_update_secret \
        "finefindslk/${ENVIRONMENT}/database" \
        "$db_secret_json" \
        "Database credentials for ${PROJECT} ${ENVIRONMENT}" \
        "$REGION"

    # SonarQube token
    sonar_token_json=$(printf '{"token":"%s"}' "$SONAR_TOKEN")
    create_or_update_secret \
        "finefindslk/${ENVIRONMENT}/sonar-token" \
        "$sonar_token_json" \
        "SonarQube token for ${PROJECT} ${ENVIRONMENT}" \
        "$REGION"

    # Source token (GitHub PAT)
    source_token_json=$(printf '{"token":"%s"}' "$SOURCE_TOKEN")
    create_or_update_secret \
        "finefindslk/${ENVIRONMENT}/source-token" \
        "$source_token_json" \
        "Source control token for ${PROJECT} ${ENVIRONMENT}" \
        "$REGION"
    
    # Client Repository URL
    client_repo_json=$(printf '{"url":"%s"}' "$CLIENT_REPOSITORY")
    create_or_update_secret \
        "finefindslk/${ENVIRONMENT}/client-repository" \
        "$client_repo_json" \
        "Client repository URL for ${PROJECT} ${ENVIRONMENT}" \
        "$REGION"

    # Admin Repository URL
    admin_repo_json=$(printf '{"url":"%s"}' "$ADMIN_REPOSITORY")
    create_or_update_secret \
        "finefindslk/${ENVIRONMENT}/admin-repository" \
        "$admin_repo_json" \
        "Admin repository URL for ${PROJECT} ${ENVIRONMENT}" \
        "$REGION"

    # Container Image (using default AWS image)
    container_image_json='{"image":"public.ecr.aws/amazonlinux/amazonlinux:latest"}'
    create_or_update_secret \
        "finefindslk/${ENVIRONMENT}/container-image" \
        "$container_image_json" \
        "Container image URI for ${PROJECT} ${ENVIRONMENT}" \
        "$REGION"

    # Get ARNs
    echo "Retrieving secret ARNs..."
    DATABASE_ARN=$(get_secret_arn "finefindslk/${ENVIRONMENT}/database" "$REGION")
    JWT_SECRET_ARN=$(get_secret_arn "finefindslk/${ENVIRONMENT}/jwt-secret" "$REGION")
    SONAR_TOKEN_ARN=$(get_secret_arn "finefindslk/${ENVIRONMENT}/sonar-token" "$REGION")
    SOURCE_TOKEN_ARN=$(get_secret_arn "finefindslk/${ENVIRONMENT}/source-token" "$REGION")
    CLIENT_REPOSITORY_ARN=$(get_secret_arn "finefindslk/${ENVIRONMENT}/client-repository" "$REGION")
    ADMIN_REPOSITORY_ARN=$(get_secret_arn "finefindslk/${ENVIRONMENT}/admin-repository" "$REGION")
    CONTAINER_IMAGE_ARN=$(get_secret_arn "finefindslk/${ENVIRONMENT}/container-image" "$REGION")

    # Create tfvars file
    # Ensure TFVARS_PATH is relative to the workspace root if running script from root,
    # or adjust if running from a different CWD.
    # Assuming script is run from workspace root:
    TFVARS_PATH="terraform/environments/${ENVIRONMENT}/secrets.auto.tfvars"
    echo "Creating Terraform variables file at ${TFVARS_PATH}..."
    
    cat > "$TFVARS_PATH" << EOF
# Generated secrets for ${ENVIRONMENT} environment by generate-secrets.sh
# DO NOT COMMIT THIS FILE TO VERSION CONTROL
# Generated on: $(date)

# These ARNs point to secrets containing JSON objects.
# Terraform modules will parse the JSON to extract specific fields.

# JWT secret
jwt_secret_arn = "${JWT_SECRET_ARN}"

# Database secrets (username is within the 'database' secret)
db_username_arn = "${DATABASE_ARN}"
db_password_arn = "${DATABASE_ARN}"

# Token ARNs
sonar_token_arn = "${SONAR_TOKEN_ARN}"
source_token_arn = "${SOURCE_TOKEN_ARN}" # ARN for the secret containing the GitHub PAT

# Repository URL ARNs
client_repository_arn = "${CLIENT_REPOSITORY_ARN}"
admin_repository_arn = "${ADMIN_REPOSITORY_ARN}"

# Container Image ARN
container_image_arn = "${CONTAINER_IMAGE_ARN}"

# Actual values (for local reference, not directly used by Terraform root module vars of same name)
# Terraform modules will fetch these from Secrets Manager using the ARNs above.
# jwt_secret = "${JWT_SECRET}"
# db_username = "${DB_USERNAME}"
# db_password = "${DB_PASSWORD}"
# sonar_token = "${SONAR_TOKEN}"
# source_token_actual = "${SOURCE_TOKEN}" # Note: root var is 'source_token', not 'source_token_actual'
# client_repository_url_actual = "${CLIENT_REPOSITORY}"
# admin_repository_url_actual = "${ADMIN_REPOSITORY}"
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