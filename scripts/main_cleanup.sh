#!/bin/bash

# Set variables
VPC_TO_DELETE="vpc-02904de72a441762f"
INSTANCE_TO_TERMINATE="i-05331e44ed9a9ee79"
SECURITY_GROUP_TO_DELETE="sg-0f0e62583a4a92bab"

echo "Starting cleanup of duplicate resources..."

# Terminate the duplicate MongoDB instance
echo "Terminating duplicate MongoDB instance..."
aws ec2 terminate-instances --instance-ids $INSTANCE_TO_TERMINATE

# Wait for instance to terminate
echo "Waiting for instance to terminate..."
aws ec2 wait instance-terminated --instance-ids $INSTANCE_TO_TERMINATE

# Delete the security group
echo "Deleting duplicate security group..."
aws ec2 delete-security-group --group-id $SECURITY_GROUP_TO_DELETE

# Get all resources in the VPC that need to be deleted
echo "Getting resources in VPC to delete..."

# Get and delete internet gateways
IGW_IDS=$(aws ec2 describe-internet-gateways --filters "Name=attachment.vpc-id,Values=$VPC_TO_DELETE" --query 'InternetGateways[*].InternetGatewayId' --output text)
for IGW_ID in $IGW_IDS; do
    echo "Detaching and deleting internet gateway $IGW_ID..."
    aws ec2 detach-internet-gateway --internet-gateway-id $IGW_ID --vpc-id $VPC_TO_DELETE
    aws ec2 delete-internet-gateway --internet-gateway-id $IGW_ID
done

# Get and delete subnets
SUBNET_IDS=$(aws ec2 describe-subnets --filters "Name=vpc-id,Values=$VPC_TO_DELETE" --query 'Subnets[*].SubnetId' --output text)
for SUBNET_ID in $SUBNET_IDS; do
    echo "Deleting subnet $SUBNET_ID..."
    aws ec2 delete-subnet --subnet-id $SUBNET_ID
done

# Get and delete route tables
ROUTE_TABLE_IDS=$(aws ec2 describe-route-tables --filters "Name=vpc-id,Values=$VPC_TO_DELETE" --query 'RouteTables[*].RouteTableId' --output text)
for RT_ID in $ROUTE_TABLE_IDS; do
    echo "Deleting route table $RT_ID..."
    aws ec2 delete-route-table --route-table-id $RT_ID
done

# Get and delete network ACLs
NACL_IDS=$(aws ec2 describe-network-acls --filters "Name=vpc-id,Values=$VPC_TO_DELETE" --query 'NetworkAcls[*].NetworkAclId' --output text)
for NACL_ID in $NACL_IDS; do
    echo "Deleting network ACL $NACL_ID..."
    aws ec2 delete-network-acl --network-acl-id $NACL_ID
done

# Finally, delete the VPC
echo "Deleting VPC $VPC_TO_DELETE..."
aws ec2 delete-vpc --vpc-id $VPC_TO_DELETE

echo "Cleanup completed!" 