# FineFinds Infrastructure

This directory contains the AWS CDK infrastructure code for the FineFinds platform.

## Architecture

The infrastructure is organized into the following constructs:

- **VPC**: Network infrastructure with public and private subnets
- **ECS**: Container orchestration with Fargate
- **RDS**: Aurora PostgreSQL database cluster
- **MongoDB**: Atlas cluster for search functionality
- **S3**: Storage for media, uploads, and backups
- **CloudFront**: Content delivery for media and static assets
- **Cognito**: User authentication and authorization
- **WAF**: Web application firewall
- **Monitoring**: CloudWatch dashboards and alarms
- **SonarQube**: Code quality analysis
- **Amplify**: Frontend hosting for React applications

## Prerequisites

1. Install AWS CDK:
   ```bash
   npm install -g aws-cdk
   ```

2. Configure AWS credentials:
   ```bash
   aws configure
   ```

3. Install dependencies:
   ```bash
   cd infra
   npm install
   ```

## Environment Configuration

The infrastructure supports multiple environments (dev, qa, staging, prod). Each environment has its own configuration in `infra/env/`:

- `base-config.ts`: Common configuration
- `dev.ts`: Development environment
- `qa.ts`: QA environment
- `staging.ts`: Staging environment
- `prod.ts`: Production environment

## Deployment

### Manual Deployment

1. Bootstrap your AWS environment:
   ```bash
   cdk bootstrap aws://ACCOUNT-NUMBER/REGION
   ```

2. Deploy to specific environment:
   ```bash
   npm run cdk deploy dev  # For development
   npm run cdk deploy qa   # For QA
   npm run cdk deploy staging  # For staging
   npm run cdk deploy prod  # For production
   ```

### CI/CD Deployment

The infrastructure is automatically deployed through GitHub Actions using a branch-to-environment strategy:

- `main` branch → Production environment
- `staging` branch → Staging environment
- `qa` branch → QA environment
- `dev` branch → Development environment
- `sonarqube` branch → Triggers SonarQube setup

#### CI/CD Workflows

We have two key workflows:

1. **CDK Deploy (`cdk-deploy.yml`)**
   - Triggers on push to main branches (`main`, `staging`, `qa`, `dev`)
   - Deploys infrastructure to the corresponding environment
   - Sends Slack notifications on success/failure
   
2. **SonarQube Setup (`sonarqube-setup.yml`)**
   - Can be triggered manually for any environment
   - Automatically triggers on changes to the SonarQube construct in the `sonarqube` branch
   - Deploys only SonarQube infrastructure 
   - Sets up SonarQube credentials as GitHub secrets
   - Does not perform code scanning (scanning happens in application repositories)

#### Branch Protection Rules

For infrastructure safety, we maintain branch protection rules:

- Pull request approvals required for all environment branches
- Status checks must pass before merging
- Force-push disabled on protected branches

## Infrastructure Components

### VPC
- Public and private subnets across multiple AZs
- NAT Gateways for outbound internet access
- VPC endpoints for AWS services
- Security groups for network isolation

### ECS
- Fargate for serverless container execution
- Auto-scaling based on CPU and memory usage
- Load balancer for traffic distribution
- Health checks and monitoring

### RDS
- Aurora PostgreSQL cluster
- Multi-AZ deployment in production
- Automated backups and point-in-time recovery
- Performance insights and monitoring

### MongoDB
- Atlas cluster for search functionality
- Connection string stored in Secrets Manager
- IAM roles for secure access

### S3
- Media bucket with CloudFront distribution
- Uploads bucket for user content
- Backups bucket for automated backups
- Lifecycle policies for cost optimization

### CloudFront
- SSL/TLS encryption
- Geographic restrictions
- Cache optimization
- Security headers

### Cognito
- User pools for clients and admins
- Social identity providers
- Multi-factor authentication
- Password policies

### WAF
- AWS managed rules
- Rate limiting
- SQL injection protection
- Cross-site scripting protection

### Monitoring
- CloudWatch dashboards
- Custom metrics and alarms
- Log aggregation
- X-Ray tracing
- Slack notifications for alerts

### SonarQube
- Separate deployment workflow
- Code quality analysis for application repositories
- Security scanning
- Technical debt tracking

### Amplify
- React application hosting
- Custom domains
- Branch-based deployments
- Environment variables

## Security

- KMS encryption for sensitive data
- IAM roles with least privilege
- Security groups for network isolation
- WAF for web application protection
- Regular security scans

## Monitoring

- CloudWatch dashboards for:
  - ECS metrics
  - RDS performance
  - API Gateway metrics
  - WAF metrics
- Custom alarms for:
  - High CPU/Memory usage
  - Error rates
  - Latency
  - Security events
- Slack integrations for real-time alerts

## Backup and Recovery

- RDS automated backups
- S3 versioning
- Cross-region replication
- Disaster recovery procedures

## Cost Optimization

- Auto-scaling for ECS
- RDS instance sizing
- S3 lifecycle policies
- CloudFront caching

## Troubleshooting

1. Check CloudWatch logs
2. Review CloudWatch metrics
3. Check X-Ray traces
4. Verify IAM permissions
5. Check security group rules
6. Review Slack notifications for error details

## Contributing

1. Create a feature branch from the appropriate environment branch
2. Make your changes
3. Run tests: `npm test`
4. Submit a pull request to the appropriate environment branch

## License

This project is licensed under the MIT License - see the [LICENSE](../LICENSE) file for details. 