#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Function to check AWS CLI installation
check_aws_cli() {
    if ! command -v aws &> /dev/null; then
        echo -e "${RED}Error: AWS CLI is not installed${NC}"
        exit 1
    fi
}

# Function to check AWS credentials
check_aws_credentials() {
    if ! aws sts get-caller-identity &> /dev/null; then
        echo -e "${RED}Error: AWS credentials are not configured${NC}"
        exit 1
    fi
}

# Function to get existing resources
get_existing_resources() {
    local env=$1
    local prefix="${PROJECT}-${env}"
    
    echo -e "\n${YELLOW}Checking existing resources for $env environment...${NC}"
    
    # Get VPCs
    echo "Checking VPCs..."
    aws ec2 describe-vpcs --filters "Name=tag:Environment,Values=$env" --query 'Vpcs[*].[VpcId,Tags[?Key==`Name`].Value|[0]]' --output text
    
    # Get Security Groups
    echo "Checking Security Groups..."
    aws ec2 describe-security-groups --filters "Name=tag:Environment,Values=$env" --query 'SecurityGroups[*].[GroupId,GroupName]' --output text
    
    # Get IAM Roles
    echo "Checking IAM Roles..."
    aws iam list-roles --query "Roles[?starts_with(RoleName, '$prefix')].[RoleName]" --output text
    
    # Get Secrets
    echo "Checking Secrets..."
    aws secretsmanager list-secrets --query "SecretList[?starts_with(Name, '$prefix')].[Name]" --output text
    
    # Get ECS Clusters
    echo "Checking ECS Clusters..."
    aws ecs list-clusters --query "clusterArns[?contains(@, '$prefix')]" --output text
    
    # Get RDS Instances
    echo "Checking RDS Instances..."
    aws rds describe-db-instances --query "DBInstances[?starts_with(DBInstanceIdentifier, '$prefix')].[DBInstanceIdentifier]" --output text
    
    # Get Subnet Groups
    echo "Checking RDS Subnet Groups..."
    aws rds describe-db-subnet-groups --query "DBSubnetGroups[?starts_with(DBSubnetGroupName, '$prefix')].[DBSubnetGroupName]" --output text
}

# Function to clean up resources
cleanup_resources() {
    local env=$1
    local prefix="${PROJECT}-${env}"
    
    echo -e "\n${YELLOW}Cleaning up resources for $env environment...${NC}"
    
    # Clean up VPCs
    echo "Cleaning up VPCs..."
    vpcs=$(aws ec2 describe-vpcs --filters "Name=tag:Environment,Values=$env" --query 'Vpcs[*].VpcId' --output text)
    for vpc in $vpcs; do
        echo "Deleting VPC: $vpc"
        aws ec2 delete-vpc --vpc-id "$vpc" || echo "Failed to delete VPC: $vpc"
    done
    
    # Clean up Security Groups
    echo "Cleaning up Security Groups..."
    sgs=$(aws ec2 describe-security-groups --filters "Name=tag:Environment,Values=$env" --query 'SecurityGroups[*].GroupId' --output text)
    for sg in $sgs; do
        echo "Deleting Security Group: $sg"
        aws ec2 delete-security-group --group-id "$sg" || echo "Failed to delete Security Group: $sg"
    done
    
    # Clean up IAM Roles
    echo "Cleaning up IAM Roles..."
    roles=$(aws iam list-roles --query "Roles[?starts_with(RoleName, '$prefix')].[RoleName]" --output text)
    for role in $roles; do
        echo "Deleting IAM Role: $role"
        aws iam delete-role --role-name "$role" || echo "Failed to delete IAM Role: $role"
    done
    
    # Clean up Secrets
    echo "Cleaning up Secrets..."
    secrets=$(aws secretsmanager list-secrets --query "SecretList[?starts_with(Name, '$prefix')].[Name]" --output text)
    for secret in $secrets; do
        echo "Deleting Secret: $secret"
        aws secretsmanager delete-secret --secret-id "$secret" --force-delete-without-recovery || echo "Failed to delete Secret: $secret"
    done
    
    # Clean up ECS Clusters
    echo "Cleaning up ECS Clusters..."
    clusters=$(aws ecs list-clusters --query "clusterArns[?contains(@, '$prefix')]" --output text)
    for cluster in $clusters; do
        echo "Deleting ECS Cluster: $cluster"
        aws ecs delete-cluster --cluster "$cluster" || echo "Failed to delete ECS Cluster: $cluster"
    done
    
    # Clean up RDS Instances
    echo "Cleaning up RDS Instances..."
    rds_instances=$(aws rds describe-db-instances --query "DBInstances[?starts_with(DBInstanceIdentifier, '$prefix')].[DBInstanceIdentifier]" --output text)
    for instance in $rds_instances; do
        echo "Deleting RDS Instance: $instance"
        aws rds delete-db-instance --db-instance-identifier "$instance" --skip-final-snapshot || echo "Failed to delete RDS Instance: $instance"
    done
    
    # Clean up Subnet Groups
    echo "Cleaning up RDS Subnet Groups..."
    subnet_groups=$(aws rds describe-db-subnet-groups --query "DBSubnetGroups[?starts_with(DBSubnetGroupName, '$prefix')].[DBSubnetGroupName]" --output text)
    for group in $subnet_groups; do
        echo "Deleting RDS Subnet Group: $group"
        aws rds delete-db-subnet-group --db-subnet-group-name "$group" || echo "Failed to delete RDS Subnet Group: $group"
    done
}

# Main script
echo "Starting AWS resource cleanup..."

# Check prerequisites
check_aws_cli
check_aws_credentials

# Set project name
PROJECT="finefinds"

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

# Ask for confirmation
echo -e "${YELLOW}This will list all existing resources for the $ENV environment.${NC}"
read -p "Do you want to proceed? (y/N) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Operation cancelled"
    exit 1
fi

# Get existing resources
get_existing_resources "$ENV"

# Ask for cleanup confirmation
echo -e "\n${RED}WARNING: This will delete all listed resources for the $ENV environment.${NC}"
read -p "Do you want to proceed with cleanup? (y/N) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Cleanup cancelled"
    exit 1
fi

# Perform cleanup
cleanup_resources "$ENV"

echo -e "\n${GREEN}Cleanup completed for $ENV environment${NC}" 