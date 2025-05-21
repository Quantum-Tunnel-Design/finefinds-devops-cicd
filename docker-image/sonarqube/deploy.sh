#!/bin/bash

# Script to build and deploy the SonarQube Docker image to ECR

set -e

# Set variables
AWS_ACCOUNT_ID=891076991993
AWS_REGION=us-east-1
ECR_REPO=finefinds-base/sonarqube
IMAGE_TAG=$(date +%Y%m%d)-$(git rev-parse --short HEAD)

echo "=== Building and deploying SonarQube image ==="
echo "AWS Account: $AWS_ACCOUNT_ID"
echo "Region: $AWS_REGION"
echo "ECR Repository: $ECR_REPO"
echo "Image Tag: $IMAGE_TAG"

# Authenticate to ECR
echo "Logging in to ECR..."
aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com

# Ensure repository exists
echo "Checking if repository exists..."
aws ecr describe-repositories --repository-names $ECR_REPO --region $AWS_REGION || \
  aws ecr create-repository --repository-name $ECR_REPO --region $AWS_REGION

# Build the image
echo "Building Docker image..."
docker build -t $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$ECR_REPO:$IMAGE_TAG \
             -t $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$ECR_REPO:latest .

# Push the image to ECR
echo "Pushing image to ECR..."
docker push $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$ECR_REPO:$IMAGE_TAG
docker push $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$ECR_REPO:latest

echo "=== Image successfully built and pushed ==="
echo "Image URI: $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$ECR_REPO:$IMAGE_TAG"
echo 
echo "Update your ECS task definition to use this new image."
echo "Consider running a forced redeployment of your ECS service." 