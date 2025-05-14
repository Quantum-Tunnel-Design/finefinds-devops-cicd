# SonarQube Docker Image for FineFinds

This directory contains a custom SonarQube Docker image configured for optimal performance in AWS ECS environments.

## Key Features

- Optimized memory settings for Elasticsearch and Java processes
- Enhanced health checks for improved reliability
- Diagnostic tools for troubleshooting container health issues
- Volume configurations for data persistence
- Container-friendly configurations with extended startup grace period

## Local Testing

You can test the image locally before pushing to ECR:

```bash
# Build and start the containers
docker-compose up -d

# Check logs
docker-compose logs -f

# Verify the container is running and healthy
docker ps
```

SonarQube will be available at http://localhost:9000 with default credentials (admin/admin).

## Building and Pushing to ECR

```bash
# Set your AWS account ID and region
export AWS_ACCOUNT_ID=891076991993
export AWS_REGION=us-east-1
export ECR_REPO=finefinds-base/sonarqube

# Login to ECR
aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com

# Build and tag the image
docker build -t $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$ECR_REPO:latest .

# Push the image to ECR
docker push $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$ECR_REPO:latest
```

## Memory and Performance Tuning

The following environment variables are configured in the Dockerfile:

- `SONAR_WEB_JAVAADDITIONALOPTS`: Memory settings for web server (1GB)
- `SONAR_SEARCH_JAVAADDITIONALOPTS`: Memory settings for Elasticsearch (512MB)
- `SONAR_CE_JAVAADDITIONALOPTS`: Memory settings for Compute Engine (1GB)

Adjust these values in the Dockerfile based on your ECS task configuration.

## Troubleshooting

If the container keeps restarting in ECS:

1. Check CloudWatch logs for errors
2. Ensure ECS task has sufficient memory (recommended: at least 4GB)
3. Verify database connectivity and credentials
4. Check health check logs in `/opt/sonarqube/logs/healthcheck.log`
5. Ensure all required volumes are mounted correctly

For persistent issues, you can modify the `healthcheck.sh` script to add more diagnostic information. 