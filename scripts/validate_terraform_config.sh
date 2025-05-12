#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Function to check if a file exists
check_file() {
    if [ ! -f "$1" ]; then
        echo -e "${RED}Error: File $1 does not exist${NC}"
        exit 1
    fi
}

# Function to validate VPC CIDR ranges
validate_vpc_cidrs() {
    local env=$1
    local cidr=$(grep -A 4 "vpc_cidr" "terraform/environments/$env/main.tf" | grep -o '"[0-9]\+\.[0-9]\+\.[0-9]\+\.[0-9]\+/[0-9]\+"')
    
    case $env in
        "sandbox") expected="10.0.0.0/16" ;;
        "dev") expected="10.1.0.0/16" ;;
        "staging") expected="10.3.0.0/16" ;;
        "qa") expected="10.4.0.0/16" ;;
        "prod") expected="10.2.0.0/16" ;;
    esac
    
    if [ "$cidr" != "\"$expected\"" ]; then
        echo -e "${RED}Error: Invalid VPC CIDR for $env. Expected $expected, got $cidr${NC}"
        exit 1
    fi
}

# Function to validate resource configurations
validate_resources() {
    local env=$1
    local file="terraform/environments/$env/main.tf"
    
    # Check for required modules
    required_modules=("vpc" "secrets" "security" "storage" "backend" "amplify")
    for module in "${required_modules[@]}"; do
        if ! grep -q "module \"$module\"" "$file"; then
            echo -e "${RED}Error: Missing module $module in $env${NC}"
            exit 1
        fi
    done
    
    # Check for secret_suffix variable
    if ! grep -q "variable \"secret_suffix\"" "$file"; then
        echo -e "${RED}Error: Missing secret_suffix variable in $env${NC}"
        exit 1
    fi
    
    # Check for use_existing_secrets
    if ! grep -q "use_existing_secrets = false" "$file"; then
        echo -e "${RED}Error: use_existing_secrets not set to false in $env${NC}"
        exit 1
    fi
}

# Function to validate dependencies
validate_dependencies() {
    local env=$1
    local file="terraform/environments/$env/main.tf"
    
    # Check for depends_on blocks
    required_deps=(
        "module.security.*depends_on.*module.secrets"
        "module.storage.*depends_on.*module.vpc.*module.security"
        "module.backend.*depends_on.*module.vpc.*module.security.*module.storage"
        "module.amplify.*depends_on.*module.compute"
    )
    
    for dep in "${required_deps[@]}"; do
        if ! grep -q "$dep" "$file"; then
            echo -e "${RED}Error: Missing dependency $dep in $env${NC}"
            exit 1
        fi
    done
}

# Main validation
echo "Starting Terraform configuration validation..."

# Check all environment files exist
environments=("sandbox" "dev" "staging" "qa" "prod")
for env in "${environments[@]}"; do
    check_file "terraform/environments/$env/main.tf"
done

# Validate each environment
for env in "${environments[@]}"; do
    echo -e "\n${YELLOW}Validating $env environment...${NC}"
    
    # Validate VPC CIDR ranges
    validate_vpc_cidrs "$env"
    
    # Validate resource configurations
    validate_resources "$env"
    
    # Validate dependencies
    validate_dependencies "$env"
    
    echo -e "${GREEN}✓ $env environment validation passed${NC}"
done

echo -e "\n${GREEN}All validations passed successfully!${NC}" 