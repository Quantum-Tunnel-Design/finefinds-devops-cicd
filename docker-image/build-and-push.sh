#!/bin/bash
set -e

# Set your AWS account ID and region
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
AWS_REGION="us-east-1"
REPO_NAME="finefinds-base/node-20-alpha"
TAG="latest"

# Login to ECR
echo "Logging in to Amazon ECR..."
aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com

# Create the repository if it doesn't exist
echo "Creating repository if it doesn't exist..."
aws ecr describe-repositories --repository-names $REPO_NAME --region $AWS_REGION || \
   aws ecr create-repository --repository-name $REPO_NAME --region $AWS_REGION

# Set up buildx
echo "Setting up Docker buildx..."
docker buildx create --name multiarch --driver docker-container --use || true
docker buildx inspect --bootstrap

# Build and push multi-architecture image
echo "Building and pushing multi-architecture image..."
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  -t $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$REPO_NAME:$TAG \
  -f ./docker-image/Dockerfile.node \
  --push \
  .

echo "Done! Multi-architecture image is now available in ECR." 