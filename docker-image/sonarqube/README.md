# SonarQube Docker Image for FineFinds

This directory contains a custom SonarQube Docker image configured for optimal performance in AWS ECS environments.

## Key Features

- Optimized memory settings for Elasticsearch and Java processes
- Enhanced health checks for improved reliability
- Diagnostic tools for troubleshooting container health issues
- Volume configurations for data persistence
- Container-friendly configurations with extended startup grace period
- Custom entrypoint script with database connectivity validation
- Improved error handling and diagnostics

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
# Use the deploy script
./deploy.sh

# Or manually:
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

## ECS Configuration

For optimal performance in ECS, ensure your task definition has:

1. **Task Memory**: At least 4GB (recommended 6-8GB for production)
2. **CPU Units**: At least 1 vCPU (1024 units, recommended 2 vCPU for production)
3. **Essential Container**: Set to true
4. **Container Memory Limits**: Set to match task memory
5. **Health Check**:
   ```json
   {
     "command": ["CMD-SHELL", "/opt/sonarqube/bin/healthcheck.sh"],
     "interval": 30,
     "timeout": 10,
     "retries": 5,
     "startPeriod": 180
   }
   ```
6. **Volumes**:
   - Mount EFS volumes for `/opt/sonarqube/data`, `/opt/sonarqube/logs`, `/opt/sonarqube/extensions`, and `/opt/sonarqube/temp`
   - Or use ephemeral storage for non-production environments

## Troubleshooting

If the container keeps restarting in ECS:

1. **Check CloudWatch logs** for errors:
   ```bash
   aws logs get-log-events --log-group-name "<your-log-group>" --log-stream-name "<latest-stream>"
   ```

2. **ECS Task Size**: Ensure task has sufficient memory (at least 4GB)
   ```bash
   aws ecs describe-task-definition --task-definition <task-def-name>
   ```

3. **Database Connectivity**: Verify database is accessible from ECS
   ```bash
   aws rds describe-db-instances --db-instance-identifier <db-id>
   ```

4. **Security Groups**: Ensure ECS security group allows outbound to RDS
   ```bash
   aws ec2 describe-security-groups --group-ids <security-group-id>
   ```

5. **Force redeployment**: Try forcing a redeployment of the service
   ```bash
   aws ecs update-service --cluster <cluster-name> --service <service-name> --force-new-deployment
   ```

6. **Health Checks**: Check `/opt/sonarqube/logs/healthcheck.log` inside the container

For additional diagnostics, you can exec into the running container in Fargate:
```bash
aws ecs execute-command --cluster <cluster-name> --task <task-id> --container sonarqube --command "/bin/bash" --interactive
``` 