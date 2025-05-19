#!/bin/bash

set -e

# Get environment from argument or use 'dev' as default
ENVIRONMENT=${1:-dev}
APP_ID_CLIENT=$2
APP_ID_ADMIN=$3

if [ -z "$APP_ID_CLIENT" ] || [ -z "$APP_ID_ADMIN" ]; then
    echo "Usage: $0 [environment] <client-app-id> <admin-app-id>"
    echo "Example: $0 dev abc123def456 ghi789jkl012"
    exit 1
fi

# Function to get Cognito details
get_cognito_details() {
    local env=$1
    local user_pool_id
    local client_id

    # Get User Pool ID
    user_pool_id=$(aws cloudformation describe-stacks \
        --stack-name FineFinds-${env} \
        --query 'Stacks[0].Outputs[?OutputKey==`ClientUserPoolId`].OutputValue' \
        --output text)

    # Get Client ID
    client_id=$(aws cognito-idp list-user-pool-clients \
        --user-pool-id $user_pool_id \
        --query 'UserPoolClients[0].ClientId' \
        --output text)

    echo "$user_pool_id $client_id"
}

# Function to update Amplify environment variables
update_amplify_env() {
    local app_id=$1
    local env_file=$2
    local env=$3
    local cognito_details=$4

    # Read environment variables from JSON file
    if [ ! -f "$env_file" ]; then
        echo "Error: $env_file not found"
        exit 1
    fi

    # Extract Cognito details
    read -r user_pool_id client_id <<< "$cognito_details"

    # Create temporary file with merged environment variables
    local temp_file=$(mktemp)
    
    # Merge JSON from file with Cognito variables
    jq --arg env "$env" \
       --arg user_pool_id "$user_pool_id" \
       --arg client_id "$client_id" \
       --arg api_url "https://api.${env}.finefindslk.com" \
       '. + {
           "NEXT_PUBLIC_ENV": $env,
           "NEXT_PUBLIC_API_URL": $api_url,
           "NEXT_PUBLIC_COGNITO_USER_POOL_ID": $user_pool_id,
           "NEXT_PUBLIC_COGNITO_CLIENT_ID": $client_id,
           "NEXT_PUBLIC_AWS_REGION": "us-east-1"
       }' "$env_file" > "$temp_file"

    # Update Amplify environment variables
    echo "Updating environment variables for app $app_id..."
    aws amplify update-branch \
        --app-id "$app_id" \
        --branch-name "$ENVIRONMENT" \
        --environment-variables "$(cat $temp_file)"

    # Clean up
    rm "$temp_file"
}

# Get Cognito details
echo "Getting Cognito details..."
COGNITO_DETAILS=$(get_cognito_details $ENVIRONMENT)

# Update client app environment variables
echo "Updating client app environment variables..."
update_amplify_env "$APP_ID_CLIENT" "client.env.json" "$ENVIRONMENT" "$COGNITO_DETAILS"

# Update admin app environment variables
echo "Updating admin app environment variables..."
update_amplify_env "$APP_ID_ADMIN" "admin.env.json" "$ENVIRONMENT" "$COGNITO_DETAILS"

echo "Environment variables updated successfully!" 