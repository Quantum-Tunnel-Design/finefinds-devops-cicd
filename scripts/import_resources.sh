#!/bin/bash

# Exit on error
set -e

# Get AWS account ID
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
ENVIRONMENT="dev"
PROJECT="finefindslk"
NAME_PREFIX="${PROJECT}-${ENVIRONMENT}"

echo "Starting resource import for ${NAME_PREFIX}..."

# Import XRay Group
echo "Importing XRay Group..."
terraform import module.monitoring.aws_xray_group.main "${NAME_PREFIX}-xray"

# Import CloudWatch Log Groups
echo "Importing CloudWatch Log Groups..."
terraform import module.networking.aws_cloudwatch_log_group.flow_log[0] "/aws/vpc/${NAME_PREFIX}-flow-log"
terraform import module.compute.aws_cloudwatch_log_group.main "/ecs/${NAME_PREFIX}"

# Import RDS Subnet Group
echo "Importing RDS Subnet Group..."
terraform import module.rds.aws_db_subnet_group.main "${NAME_PREFIX}-rds-subnet-group"

# Import Backup Plan
echo "Importing Backup Plan..."
BACKUP_PLAN_ID=$(aws backup list-backup-plans --query "BackupPlansList[?BackupPlanName=='${NAME_PREFIX}-backup-plan-${ENVIRONMENT}'].BackupPlanId" --output text)
terraform import module.security.aws_backup_plan.main[0] "${BACKUP_PLAN_ID}"

# Import IAM Roles
echo "Importing IAM Roles..."
terraform import module.security.aws_iam_role.cloudwatch[0] "${NAME_PREFIX}-cloudwatch-role"
terraform import module.compute.aws_iam_role.task_execution "${NAME_PREFIX}-task-execution-role"
terraform import module.compute.aws_iam_role.task "${NAME_PREFIX}-task-role"

# Import VPC Flow Log
echo "Importing VPC Flow Log..."
VPC_ID=$(aws ec2 describe-vpcs --filters "Name=tag:Name,Values=${NAME_PREFIX}-vpc" --query "Vpcs[0].VpcId" --output text)
FLOW_LOG_ID=$(aws ec2 describe-flow-logs --filter "Name=resource-id,Values=${VPC_ID}" --query "FlowLogs[0].FlowLogId" --output text)
terraform import module.networking.aws_flow_log.main[0] "${FLOW_LOG_ID}"

# Import ECS Resources
echo "Importing ECS Resources..."
CLUSTER_NAME="${NAME_PREFIX}-cluster"
SERVICE_NAME="${NAME_PREFIX}-service"
TASK_DEFINITION="${NAME_PREFIX}-task"

terraform import module.compute.aws_ecs_cluster.main "${CLUSTER_NAME}"
terraform import module.compute.aws_ecs_service.main "${CLUSTER_NAME}/${SERVICE_NAME}"

# Get the latest task definition revision
TASK_DEFINITION_ARN=$(aws ecs describe-task-definition --task-definition "${TASK_DEFINITION}" --query "taskDefinition.taskDefinitionArn" --output text)
terraform import module.compute.aws_ecs_task_definition.main "${TASK_DEFINITION_ARN}"

# Import Security Groups
echo "Importing Security Groups..."
terraform import module.compute.aws_security_group.tasks "${NAME_PREFIX}-tasks-sg"
terraform import module.alb.aws_security_group.main "${NAME_PREFIX}-alb-sg"
terraform import module.rds.aws_security_group.main "${NAME_PREFIX}-rds-sg"

echo "Resource import completed successfully!" 