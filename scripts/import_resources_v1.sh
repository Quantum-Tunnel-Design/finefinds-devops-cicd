#!/bin/bash

# Import IAM Roles
terraform import module.ecs.aws_iam_role.ecs_execution_role finefindslk-dev-ecs-execution-role
terraform import module.ecs.aws_iam_role.ecs_task_role finefindslk-dev-ecs-task-role
terraform import module.mongodb.aws_iam_role.ecs_execution_role finefindslk-dev-mongodb-execution-role
terraform import module.mongodb.aws_iam_role.ecs_task_role finefindslk-dev-mongodb-task-role
terraform import module.monitoring.aws_iam_role.grafana finefindslk-dev-grafana
terraform import module.sonarqube.aws_iam_role.ecs_execution_role finefindslk-dev-sonarqube-execution-role
terraform import module.sonarqube.aws_iam_role.ecs_task_role finefindslk-dev-sonarqube-task-role

# Import CloudWatch Log Group
terraform import module.monitoring.aws_cloudwatch_log_group.ecs /ecs/finefindslk-dev

# Import EFS File System
terraform import module.sonarqube.aws_efs_file_system.sonarqube fs-06f4ecd261d23aa8d

# Import ALB Target Group
terraform import module.ecs.aws_lb_target_group.app finefindslk-dev-tg

# Import SonarQube Secret
terraform import module.sonarqube.aws_secretsmanager_secret.sonarqube_password finefindslk-dev-sonarqube-password 