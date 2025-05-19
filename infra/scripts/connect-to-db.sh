#!/bin/bash

# Check if key file exists
KEY_FILE="finefinds-dev-bastion.pem"
if [ ! -f "$KEY_FILE" ]; then
    echo "Creating new key pair..."
    aws ec2 create-key-pair --key-name finefinds-dev-bastion --query 'KeyMaterial' --output text > "$KEY_FILE"
    chmod 400 "$KEY_FILE"
    echo "Key pair created and saved to $KEY_FILE"
fi

# Get the bastion host IP
BASTION_IP=$(aws cloudformation describe-stacks --stack-name FineFindsV1-Dev --query 'Stacks[0].Outputs[?OutputKey==`BastionPublicIp`].OutputValue' --output text)

# Get the database endpoint
DB_ENDPOINT=$(aws cloudformation describe-stacks --stack-name FineFindsV1-Dev --query 'Stacks[0].Outputs[?OutputKey==`DatabaseEndpoint`].OutputValue' --output text)

# Get the database credentials
DB_SECRET=$(aws secretsmanager get-secret-value --secret-id finefinds-dev-db-connection --query 'SecretString' --output text)
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