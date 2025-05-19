#!/bin/bash

# Get environment from argument or use 'dev' as default
ENVIRONMENT=${1:-dev}
KEY_FILE="finefinds-${ENVIRONMENT}-bastion.pem"

# Check if key file exists
if [ ! -f "$KEY_FILE" ]; then
    echo "Error: Key file $KEY_FILE not found. Please run setup-bastion-key.sh first."
    exit 1
fi

# Get the bastion host IP
BASTION_IP=$(aws cloudformation describe-stacks --stack-name FineFinds-${ENVIRONMENT^} --query 'Stacks[0].Outputs[?OutputKey==`BastionPublicIp`].OutputValue' --output text)

# Get the database endpoint
DB_ENDPOINT=$(aws cloudformation describe-stacks --stack-name FineFinds-${ENVIRONMENT^} --query 'Stacks[0].Outputs[?OutputKey==`DatabaseEndpoint`].OutputValue' --output text)

# Get the database credentials
DB_SECRET=$(aws secretsmanager get-secret-value --secret-id finefinds-${ENVIRONMENT}-db-connection --query 'SecretString' --output text)
DB_USERNAME=$(echo $DB_SECRET | jq -r '.username')
DB_PASSWORD=$(echo $DB_SECRET | jq -r '.password')

echo "Setting up SSH tunnel..."
echo "Bastion IP: $BASTION_IP"
echo "Database Endpoint: $DB_ENDPOINT"
echo "Database Username: $DB_USERNAME"
echo ""
echo "To connect to the database, use:"
echo "psql \"postgresql://$DB_USERNAME:$DB_PASSWORD@localhost:5432/finefinds\""
echo ""
echo "Press Ctrl+C to stop the tunnel when done."

# Create the SSH tunnel
ssh -i "$KEY_FILE" -L 5432:$DB_ENDPOINT:5432 ec2-user@$BASTION_IP 