# ALB Security Group
terraform import module.alb.aws_security_group.main sg-0773f31f2b8f4517f

# ALB Target Group
echo "Importing ALB Target Group finefindslk-dev-tg"
terraform import module.alb.aws_lb_target_group.main arn:aws:elasticloadbalancing:us-east-1:891076991993:targetgroup/finefindslk-dev-tg/b55da6771d901457

# ECR Repositories
echo "Importing ECR Repository finefindslk-dev-client-repo"
terraform import module.amplify.aws_ecr_repository.client finefindslk-dev-client-repo

echo "Importing ECR Repository finefindslk-dev-admin-repo"
terraform import module.amplify.aws_ecr_repository.admin finefindslk-dev-admin-repo

echo "Importing ECR Repository finefindslk-dev"
terraform import module.ecr.aws_ecr_repository.main finefindslk-dev

# CloudWatch Log Group
echo "Importing CloudWatch Log Group /ecs/finefindslk-dev"
terraform import module.monitoring.aws_cloudwatch_log_group.app /ecs/finefindslk-dev

# XRay Group
echo "Importing XRay Group finefindslk-dev-xray"
terraform import module.monitoring.aws_xray_group.main finefindslk-dev-xray

# S3 Bucket for CloudTrail
echo "Importing S3 Bucket finefindslk-dev-cloudtrail"
terraform import module.monitoring.aws_s3_bucket.cloudtrail finefindslk-dev-cloudtrail

# RDS DB Subnet Group
echo "Importing RDS DB Subnet Group finefindslk-dev-rds-subnet-group"
terraform import module.rds.aws_db_subnet_group.main finefindslk-dev-rds-subnet-group

# Secrets Manager Secrets
echo "Importing Secret finefindslk/dev/database"
terraform import module.secrets.aws_secretsmanager_secret.database finefindslk/dev/database

echo "Importing Secret finefindslk/dev/sonar-token"
terraform import module.secrets.aws_secretsmanager_secret.sonar_token finefindslk/dev/sonar-token

echo "Importing Secret finefindslk/dev/source-token"
terraform import module.secrets.aws_secretsmanager_secret.source_token finefindslk/dev/source-token

echo "Importing Secret finefindslk/dev/client-repository"
terraform import module.secrets.aws_secretsmanager_secret.client_repository finefindslk/dev/client-repository

echo "Importing Secret finefindslk/dev/admin-repository"
terraform import module.secrets.aws_secretsmanager_secret.admin_repository finefindslk/dev/admin-repository

echo "Importing Secret finefindslk/dev/container-image"
terraform import module.secrets.aws_secretsmanager_secret.container_image finefindslk/dev/container-image

# KMS Alias
echo "Importing KMS Alias alias/finefindslk-dev-kms-key"
terraform import module.security.aws_kms_alias.main[0] alias/finefindslk-dev-kms-key

# Backup Vault
echo "Importing Backup Vault finefindslk-dev-backup-vault"
terraform import module.security.aws_backup_vault.main[0] finefindslk-dev-backup-vault

# IAM Role for CloudWatch
echo "Importing IAM Role finefindslk-dev-cloudwatch-role"
terraform import module.security.aws_iam_role.cloudwatch[0] finefindslk-dev-cloudwatch-role

# S3 Buckets (managed by module.storage)
echo "Importing S3 Bucket finefindslk-dev-uploads"
terraform import module.storage.aws_s3_bucket.buckets["uploads"] finefindslk-dev-uploads

echo "Importing S3 Bucket finefindslk-dev-backups"
terraform import module.storage.aws_s3_bucket.buckets["backups"] finefindslk-dev-backups

echo "Importing S3 Bucket finefindslk-dev-static-assets"
terraform import module.storage.aws_s3_bucket.buckets["static"] finefindslk-dev-static-assets

echo "All import commands prepared." 