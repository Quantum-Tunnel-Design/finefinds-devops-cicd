#!/bin/bash

# Get environment from argument or use 'dev' as default
ENVIRONMENT=${1:-dev}
KEY_FILE="$(dirname "$0")/finefinds-${ENVIRONMENT}-bastion.pem"

# Check if key file exists
if [ ! -f "$KEY_FILE" ]; then
    echo "Error: Key file $KEY_FILE not found. Please run setup-bastion-key.sh first."
    exit 1
fi

# Get the bastion host IP
BASTION_IP=$(aws cloudformation describe-stacks --stack-name FineFinds-${ENVIRONMENT} --query 'Stacks[0].Outputs[?OutputKey==`BastionBastionPublicIp700A555F`].OutputValue' --output text)

if [ -z "$BASTION_IP" ]; then
    echo "Error: Could not retrieve bastion IP from CloudFormation outputs"
    exit 1
fi

# Get the SSH username (default to ec2-user if not found in outputs)
SSH_USERNAME=$(aws cloudformation describe-stacks --stack-name FineFinds-${ENVIRONMENT} --query 'Stacks[0].Outputs[?OutputKey==`BastionSshUsername`].OutputValue' --output text)
SSH_USERNAME=${SSH_USERNAME:-ec2-user}

# Get the database endpoint
DB_ENDPOINT=$(aws cloudformation describe-stacks --stack-name FineFinds-${ENVIRONMENT} --query 'Stacks[0].Outputs[?OutputKey==`DatabaseEndpoint`].OutputValue' --output text)

if [ -z "$DB_ENDPOINT" ]; then
    echo "Error: Could not retrieve database endpoint from CloudFormation outputs"
    exit 1
fi

# Get the database credentials
DB_SECRET=$(aws secretsmanager get-secret-value --secret-id finefinds-${ENVIRONMENT}-rds-connection --query 'SecretString' --output text)
DB_USERNAME=$(echo $DB_SECRET | jq -r '.username')
DB_PASSWORD=$(echo $DB_SECRET | jq -r '.password')

echo "Setting up SSH tunnel..."
echo "Bastion IP: $BASTION_IP"
echo "SSH Username: $SSH_USERNAME"
echo "Database Endpoint: $DB_ENDPOINT"
echo "Database Username: $DB_USERNAME"
echo ""
echo "To connect to the database, use:"
echo "psql \"postgresql://$DB_USERNAME:$DB_PASSWORD@localhost:5432/finefinds\""
echo ""
echo "Press Ctrl+C to stop the tunnel when done."

# Create the SSH tunnel
ssh -i "$KEY_FILE" -L 5432:$DB_ENDPOINT:5432 $SSH_USERNAME@$BASTION_IP 