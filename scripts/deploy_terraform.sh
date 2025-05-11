#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Function to check prerequisites
check_prerequisites() {
    echo "Checking prerequisites..."
    
    # Check AWS CLI
    if ! command -v aws &> /dev/null; then
        echo -e "${RED}Error: AWS CLI is not installed${NC}"
        exit 1
    fi
    
    # Check AWS credentials
    if ! aws sts get-caller-identity &> /dev/null; then
        echo -e "${RED}Error: AWS credentials are not configured${NC}"
        exit 1
    fi
    
    # Check Terraform
    if ! command -v terraform &> /dev/null; then
        echo -e "${RED}Error: Terraform is not installed${NC}"
        exit 1
    fi
    
    # Check required environment variables
    if [ -z "$AWS_REGION" ]; then
        echo -e "${RED}Error: AWS_REGION environment variable is not set${NC}"
        exit 1
    fi
    
    if [ -z "$TF_WORKSPACE" ]; then
        echo -e "${RED}Error: TF_WORKSPACE environment variable is not set${NC}"
        exit 1
    fi
}

# Function to validate Terraform configuration
validate_terraform() {
    local env=$1
    echo -e "\n${YELLOW}Validating Terraform configuration for $env environment...${NC}"
    
    cd "terraform/environments/$env" || exit 1
    
    # Initialize Terraform
    echo "Initializing Terraform..."
    terraform init -input=false || exit 1
    
    # Validate configuration
    echo "Validating configuration..."
    terraform validate || exit 1
    
    # Format check
    echo "Checking formatting..."
    terraform fmt -check || {
        echo -e "${YELLOW}Warning: Terraform files are not properly formatted${NC}"
        echo "Running terraform fmt..."
        terraform fmt
    }
    
    cd ../../..
}

# Function to plan Terraform changes
plan_terraform() {
    local env=$1
    echo -e "\n${YELLOW}Planning Terraform changes for $env environment...${NC}"
    
    cd "terraform/environments/$env" || exit 1
    
    # Create plan file
    terraform plan -input=false -out=tfplan || exit 1
    
    cd ../../..
}

# Function to apply Terraform changes
apply_terraform() {
    local env=$1
    echo -e "\n${YELLOW}Applying Terraform changes for $env environment...${NC}"
    
    cd "terraform/environments/$env" || exit 1
    
    # Apply changes
    terraform apply -input=false -auto-approve tfplan || exit 1
    
    cd ../../..
}

# Function to run validation script
run_validation() {
    local env=$1
    echo -e "\n${YELLOW}Running validation script for $env environment...${NC}"
    
    ./scripts/validate_terraform_config.sh "$env" || {
        echo -e "${RED}Validation failed${NC}"
        exit 1
    }
}

# Main script
echo "Starting Terraform deployment..."

# Check prerequisites
check_prerequisites

# Get environment from command line argument
if [ -z "$1" ]; then
    echo -e "${RED}Error: Please specify an environment (sandbox|dev|staging|qa|prod)${NC}"
    exit 1
fi

ENV=$1

# Validate environment
case $ENV in
    "sandbox"|"dev"|"staging"|"qa"|"prod")
        ;;
    *)
        echo -e "${RED}Error: Invalid environment. Use: sandbox, dev, staging, qa, or prod${NC}"
        exit 1
        ;;
esac

# Set Terraform workspace
export TF_WORKSPACE=$ENV

# Run validation script
run_validation "$ENV"

# Validate Terraform configuration
validate_terraform "$ENV"

# Plan changes
plan_terraform "$ENV"

# Ask for confirmation before applying
if [ "$CI" != "true" ]; then
    echo -e "\n${YELLOW}Review the plan above.${NC}"
    read -p "Do you want to apply these changes? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Deployment cancelled"
        exit 1
    fi
fi

# Apply changes
apply_terraform "$ENV"

echo -e "\n${GREEN}Deployment completed successfully for $ENV environment${NC}" 