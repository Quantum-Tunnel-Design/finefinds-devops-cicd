# DevOps Procedures

This document provides step-by-step procedures for common DevOps tasks related to the FineFinds infrastructure.

## Environment Setup

### Setting Up Local Development Environment

1. **Clone the Repository**
   ```bash
   git clone https://github.com/finefinds/finefinds-devops-cicd.git
   cd finefinds-devops-cicd
   ```

2. **Install Dependencies**
   ```bash
   npm install
   ```

3. **Configure AWS CLI**
   ```bash
   aws configure
   ```
   Enter your AWS access key, secret key, default region, and output format.

4. **Bootstrap CDK (First-time only)**
   ```bash
   npx cdk bootstrap aws://<account-id>/<region>
   ```

### Environment Configuration

1. **Create/Modify Environment Config**
   - Duplicate an existing environment config:
     ```bash
     cp infra/env/dev.ts infra/env/new-env.ts
     ```
   - Edit the configuration with appropriate values
   - Update environment-specific settings in the config file

2. **Add New Environment to CDK App**
   - Open `infra/bin/app.ts`
   - Add new environment stack instantiation

## Deployment Procedures

### Deploying to an Environment

1. **Synthesize CloudFormation Template**
   ```bash
   npx cdk synth FineFindsStack-dev
   ```

2. **Deploy the Stack**
   ```bash
   npx cdk deploy FineFindsStack-dev
   ```

3. **Deploy to Multiple Environments**
   ```bash
   npx cdk deploy FineFindsStack-dev FineFindsStack-qa
   ```

### Destroy Infrastructure (Non-production Only)

```bash
npx cdk destroy FineFindsStack-dev
```

### Update Specific Resources

To update only specific resources:

```bash
npx cdk deploy FineFindsStack-dev --exclusively --context targets=Cognito,S3
```

## Infrastructure Management

### Scaling ECS Services

1. **Manual Scaling**
   - Navigate to AWS ECS console
   - Select the cluster and service
   - Update desired count or modify auto-scaling settings

2. **Update Min/Max Capacity in Code**
   - Modify `minCapacity` and `maxCapacity` in the environment config file
   - Deploy changes:
     ```bash
     npx cdk deploy FineFindsStack-dev
     ```

### Database Operations

#### Creating Database Snapshots

```bash
aws rds create-db-snapshot --db-instance-identifier finefinds-dev --db-snapshot-identifier finefinds-dev-snapshot-$(date +%Y%m%d)
```

#### Restoring from Snapshot

```bash
aws rds restore-db-instance-from-db-snapshot --db-instance-identifier finefinds-dev-restored --db-snapshot-identifier finefinds-dev-snapshot-20230101
```

### Managing Auto-shutdown

#### Temporarily Disable Auto-shutdown

1. Go to AWS Console > CloudWatch > Rules
2. Find rules named `finefinds-dev-ShutdownRule`
3. Disable the rule temporarily

#### Re-enable Auto-shutdown

1. Go to AWS Console > CloudWatch > Rules
2. Find the previously disabled rule
3. Enable the rule

## Cost Management

### Implementing Reserved Instances/Savings Plans

1. **Analyze Current Usage**
   - Go to AWS Cost Explorer
   - Generate Savings Plans recommendations
   - Review usage patterns over 30 days

2. **Purchase Savings Plans**
   - Go to AWS Console > Savings Plans
   - Choose Compute Savings Plans
   - Select 1-year term with partial upfront
   - Enter commitment amount based on analysis

3. **Monitor Utilization**
   - Check Savings Plans utilization weekly
   - Adjust coverage as needed

### Setting Up Budget Alerts

1. Go to AWS Console > AWS Budgets
2. Create new budget
3. Set budget amount and period (monthly)
4. Configure alerts at 50%, 80%, and 100% thresholds
5. Add email recipients for notifications

## Security Management

### Rotating IAM Access Keys

1. **Create new access key**
   ```bash
   aws iam create-access-key --user-name username
   ```

2. **Update credentials in CI/CD systems and developer machines**

3. **Deactivate old key**
   ```bash
   aws iam update-access-key --access-key-id OLD_KEY_ID --status Inactive --user-name username
   ```

4. **Delete old key after confirming new key works**
   ```bash
   aws iam delete-access-key --access-key-id OLD_KEY_ID --user-name username
   ```

### Managing Cognito User Pools

#### Creating Admin User

```bash
aws cognito-idp admin-create-user \
  --user-pool-id POOL_ID \
  --username admin@example.com \
  --user-attributes Name=email,Value=admin@example.com Name=email_verified,Value=true
```

#### Assigning User to Group

```bash
aws cognito-idp admin-add-user-to-group \
  --user-pool-id POOL_ID \
  --username admin@example.com \
  --group-name Admins
```

## Monitoring and Troubleshooting

### Viewing Application Logs

1. **View ECS Service Logs**
   ```bash
   aws logs get-log-events --log-group-name /ecs/finefinds-dev --log-stream-name STREAM_NAME
   ```

2. **Using CloudWatch Logs Insights**
   ```
   fields @timestamp, @message
   | filter @message like "ERROR"
   | sort @timestamp desc
   | limit 100
   ```

### Monitoring Infrastructure

1. **Create Custom Dashboard**
   - Go to CloudWatch > Dashboards
   - Create new dashboard
   - Add widgets for ECS CPU/Memory, RDS metrics, API Gateway requests

2. **Setting Up Custom Alarms**
   - Go to CloudWatch > Alarms
   - Create alarm based on metric
   - Configure notification action

## CI/CD Pipeline Management

### Modifying Deployment Pipeline

1. Edit `.github/workflows/deploy.yml` or equivalent CI/CD configuration
2. Update build, test, or deployment steps as needed
3. Commit and push changes

### Adding New Environment to CI/CD

1. Add environment secrets to GitHub/GitLab repository
2. Update deployment workflow to include new environment
3. Configure approval gates if needed 