#!/bin/bash

# Import IAM Roles
terraform import -var-file=terraform.tfvars -lock=false module.ecs.aws_iam_role.ecs_execution_role finefindslk-dev-ecs-execution-role
terraform import -var-file=terraform.tfvars -lock=false module.ecs.aws_iam_role.ecs_task_role finefindslk-dev-ecs-task-role
terraform import -var-file=terraform.tfvars -lock=false module.mongodb.aws_iam_role.ecs_execution_role finefindslk-dev-mongodb-execution-role
terraform import -var-file=terraform.tfvars -lock=false module.mongodb.aws_iam_role.ecs_task_role finefindslk-dev-mongodb-task-role
terraform import -var-file=terraform.tfvars -lock=false module.monitoring.aws_iam_role.grafana finefindslk-dev-grafana
terraform import -var-file=terraform.tfvars -lock=false module.sonarqube.aws_iam_role.ecs_execution_role finefindslk-dev-sonarqube-execution-role
terraform import -var-file=terraform.tfvars -lock=false module.sonarqube.aws_iam_role.ecs_task_role finefindslk-dev-sonarqube-task-role

# Import CloudWatch Log Group
terraform import -var-file=terraform.tfvars -lock=false module.monitoring.aws_cloudwatch_log_group.ecs /ecs/finefindslk-dev

# Import EFS File System
terraform import -var-file=terraform.tfvars -lock=false module.sonarqube.aws_efs_file_system.sonarqube fs-06f4ecd261d23aa8d

# Import ALB and Target Group
terraform import -var-file=terraform.tfvars -lock=false module.alb.aws_lb.main arn:aws:elasticloadbalancing:us-east-1:891076991993:loadbalancer/app/finefindslk-dev-alb/b9b707d4baffb346
terraform import -var-file=terraform.tfvars -lock=false module.ecs.aws_lb_target_group.app arn:aws:elasticloadbalancing:us-east-1:891076991993:targetgroup/finefindslk-dev-tg/bd5e0b7fa4defdca

# Import RDS and DocumentDB Subnet Groups
terraform import -var-file=terraform.tfvars -lock=false module.rds.aws_db_subnet_group.main finefindslk-dev-db-subnet-group
terraform import -var-file=terraform.tfvars -lock=false module.mongodb.aws_docdb_subnet_group.main finefindslk-dev-docdb-subnet-group

# Import SonarQube Secret
terraform import -var-file=terraform.tfvars -lock=false module.sonarqube.aws_secretsmanager_secret.sonarqube_password finefindslk-dev-sonarqube-password
