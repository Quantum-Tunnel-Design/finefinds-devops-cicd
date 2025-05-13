# Environment Configurations

This document details the specific configurations for each environment in the FineFinds infrastructure.

## Production Environment

Production is our customer-facing environment with the highest reliability and security requirements.

### Compute (ECS/Fargate)
- **CPU/Memory**: 1024 CPU units (1 vCPU), 2048MB memory
- **Min/Max Capacity**: 2/10 tasks (auto-scaling)
- **Auto-shutdown**: Not enabled (24/7 availability)

### Database
- **Type**: Aurora PostgreSQL cluster
- **Instance Type**: db.t3.small or larger
- **Multi-AZ**: Yes (high availability)
- **Backup Retention**: 7 days
- **Performance Insights**: Enabled

### Storage
- **S3 Versioning**: Enabled
- **S3 Lifecycle Rules**:
  - Transition to IA: 30 days
  - Transition to Glacier: 90 days
  - Expiration: 365 days
- **CloudFront**: Price Class All (global distribution)
- **CloudFront Logs**: Enabled

### Security
- **WAF**: Enabled with managed rules
- **Cognito Advanced Security**: Enforced
- **Backup**: Full AWS Backup enabled with retention periods:
  - Daily: 7 days
  - Weekly: 4 weeks
  - Monthly: 3 months
  - Yearly: 1 year

### Monitoring
- **CloudWatch Logs Retention**: 30 days
- **Alarms**: Comprehensive set of alarms with email and Slack notifications

## Development Environment

Development is used for ongoing feature development with cost-optimized settings.

### Compute (ECS/Fargate)
- **CPU/Memory**: 256 CPU units (0.25 vCPU), 512MB memory
- **Min/Max Capacity**: 1/2 tasks
- **Auto-shutdown**: Enabled (8 PM to 7 AM weekdays, all weekend)

### Database
- **Type**: Standard PostgreSQL (single instance)
- **Instance Type**: db.t3.micro
- **Multi-AZ**: No
- **Backup Retention**: 1 day
- **Performance Insights**: Disabled
- **Storage**: 10GB (vs 20GB in prod)

### Storage
- **S3 Versioning**: Not enabled
- **S3 Lifecycle Rules**:
  - Transition to IA: 7 days
  - Expiration: 30 days
- **CloudFront**: Price Class 100 (US/Europe only)
- **CloudFront Logs**: Disabled

### Security
- **WAF**: Disabled
- **Cognito Advanced Security**: Disabled
- **Backup**: AWS Backup disabled

### Monitoring
- **CloudWatch Logs Retention**: 1 day
- **Alarms**: Basic set of critical alarms only

## Configuration Management

All environment-specific configurations are maintained in the following files:
- Production: `infra/env/prod.ts`
- Development: `infra/env/dev.ts`
- QA/Testing: `infra/env/qa.ts`
- Sandbox: `infra/env/sandbox.ts`

These files extend the base configuration defined in `infra/env/base-config.ts`.

## Environment Promotion Process

1. Changes are first deployed to development
2. After testing, changes are promoted to QA/sandbox
3. Finally, changes are deployed to production
4. Each deployment is managed through CI/CD pipelines

## Feature Flags

Some infrastructure components are conditionally created based on environment flags:
- `enableDynamoDB`: Only creates DynamoDB tables when needed
- Environment-based conditionals: WAF, Backup, and other premium services are only enabled in production 