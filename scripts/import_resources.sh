#!/bin/bash

# Import IAM Roles
terraform import -var-file=terraform.tfvars -lock=false module.ecs.aws_iam_role.ecs_execution_role finefinds-dev-ecs-execution-role
terraform import -var-file=terraform.tfvars -lock=false module.ecs.aws_iam_role.ecs_task_role finefinds-dev-ecs-task-role
terraform import -var-file=terraform.tfvars -lock=false module.mongodb.aws_iam_role.ecs_execution_role finefinds-dev-mongodb-execution-role
terraform import -var-file=terraform.tfvars -lock=false module.mongodb.aws_iam_role.ecs_task_role finefinds-dev-mongodb-task-role
terraform import -var-file=terraform.tfvars -lock=false module.monitoring.aws_iam_role.grafana finefinds-dev-grafana
terraform import -var-file=terraform.tfvars -lock=false module.sonarqube.aws_iam_role.ecs_execution_role finefinds-dev-sonarqube-execution-role
terraform import -var-file=terraform.tfvars -lock=false module.sonarqube.aws_iam_role.ecs_task_role finefinds-dev-sonarqube-task-role

# Import CloudWatch Log Group
terraform import -var-file=terraform.tfvars -lock=false module.monitoring.aws_cloudwatch_log_group.ecs /ecs/finefinds-dev

# Import EFS File System
terraform import -var-file=terraform.tfvars -lock=false module.sonarqube.aws_efs_file_system.sonarqube fs-06f4ecd261d23aa8d

# Import ALB and Target Group
terraform import -var-file=terraform.tfvars -lock=false module.alb.aws_lb.main arn:aws:elasticloadbalancing:us-east-1:891076991993:loadbalancer/app/finefinds-dev-alb/b9b707d4baffb346
terraform import -var-file=terraform.tfvars -lock=false module.ecs.aws_lb_target_group.app arn:aws:elasticloadbalancing:us-east-1:891076991993:targetgroup/finefinds-dev-tg/bd5e0b7fa4defdca

# Import RDS and DocumentDB Subnet Groups
terraform import -var-file=terraform.tfvars -lock=false module.rds.aws_db_subnet_group.main finefinds-dev-db-subnet-group
terraform import -var-file=terraform.tfvars -lock=false module.mongodb.aws_docdb_subnet_group.main finefinds-dev-docdb-subnet-group

# Import SonarQube Secret
terraform import -var-file=terraform.tfvars -lock=false module.sonarqube.aws_secretsmanager_secret.sonarqube_password finefinds-dev-sonarqube-password
