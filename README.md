# FineFinds DevOps Setup

This repository contains the infrastructure and CI/CD configuration for the FineFinds project. It includes Terraform configurations, GitHub Actions workflows, and scripts for managing environments and secrets.

## Prerequisites

- [GitHub CLI](https://cli.github.com/) (`gh`)
- [AWS CLI](https://aws.amazon.com/cli/)
- [Terraform](https://www.terraform.io/) (v1.0.0 or later)
- [Node.js](https://nodejs.org/) (v18 or later)
- [npm](https://www.npmjs.com/) (v8 or later)

## Environment Setup

The project uses multiple environments:
- `main` (Production)
- `staging`
- `dev`
- `qa`
- `sandbox`

Each environment has its own:
- Terraform state
- AWS resources
- GitHub secrets
- Protection rules
- Quality gates

## Initial Setup

### 1. GitHub Authentication

```bash
# Login to GitHub CLI
gh auth login
```

### 2. AWS OIDC Setup

```bash
# Set required environment variables
export AWS_ACCOUNT_ID="your-aws-account-id"
export GITHUB_ORG="your-github-org"
export GITHUB_REPO="your-github-repo"

# Run the OIDC setup script
chmod +x scripts/setup-aws-oidc.sh
./scripts/setup-aws-oidc.sh
```

This script will:
- Create an OIDC provider in AWS
- Create IAM roles for each environment
- Configure trust relationships
- Attach necessary policies

### 3. GitHub Secrets Setup

```bash
# Set SonarQube credentials
export SONAR_TOKEN="your-sonarqube-token"
export SONAR_HOST_URL="your-sonarqube-url"

# Set AWS credentials for each environment
export AWS_PROD_ACCESS_KEY="prod-access-key"
export AWS_PROD_SECRET_KEY="prod-secret-key"
export AWS_STAGING_ACCESS_KEY="staging-access-key"
export AWS_STAGING_SECRET_KEY="staging-secret-key"
export AWS_DEV_ACCESS_KEY="dev-access-key"
export AWS_DEV_SECRET_KEY="dev-secret-key"
export AWS_QA_ACCESS_KEY="qa-access-key"
export AWS_QA_SECRET_KEY="qa-secret-key"
export AWS_SANDBOX_ACCESS_KEY="sandbox-access-key"
export AWS_SANDBOX_SECRET_KEY="sandbox-secret-key"

# Run the secrets setup script
chmod +x scripts/setup-github-secrets.sh
./scripts/setup-github-secrets.sh
```

### 4. Environment Protection Rules

```bash
# Run the protection rules setup script
chmod +x scripts/setup-environment-protection.sh
./scripts/setup-environment-protection.sh
```

This will configure:
- Production: 30-minute wait timer, 2 required reviewers
- Staging: 15-minute wait timer, 1 required reviewer
- Development/QA/Sandbox: No wait timer or required reviewers

## Environment-Specific Configurations

### Production (main)
- Strict quality gates
- Multi-AZ deployment
- 30-day backup retention
- 2 required reviewers
- 30-minute wait timer

### Staging
- Moderate quality gates
- Single-AZ deployment
- 14-day backup retention
- 1 required reviewer
- 15-minute wait timer

### Development/QA/Sandbox
- Basic quality gates
- Single-AZ deployment
- 7-day backup retention
- No required reviewers
- No wait timer

## GitHub Actions Workflows

### Terraform Deployment
- Triggers on push and pull requests
- Uses OIDC for AWS authentication
- Environment-specific deployments
- Automatic apply on push to main branch

### SonarQube Scan
- Triggers on push and pull requests
- Environment-specific quality gates
- Coverage and duplication thresholds
- Quality gate status check

## Security Considerations

1. **AWS Authentication**
   - Uses OIDC instead of access keys
   - Environment-specific IAM roles
   - Least privilege principle

2. **GitHub Secrets**
   - Environment-specific secrets
   - No shared credentials between environments
   - Regular rotation recommended

3. **Environment Protection**
   - Branch protection rules
   - Required reviewers
   - Wait timers for critical environments

## Maintenance

### Rotating Secrets
1. Generate new secrets
2. Update environment variables
3. Run the secrets setup script
4. Verify the changes

### Adding New Environments
1. Add environment to scripts
2. Create new AWS IAM role
3. Set up GitHub secrets
4. Configure protection rules

## Troubleshooting

### Common Issues

1. **OIDC Authentication Fails**
   - Verify OIDC provider exists
   - Check IAM role trust relationships
   - Ensure GitHub repository has correct permissions

2. **GitHub Secrets Not Available**
   - Verify GitHub CLI authentication
   - Check environment variables
   - Ensure secrets are set for the correct environment

3. **Terraform Apply Fails**
   - Check AWS credentials
   - Verify environment variables
   - Check Terraform state

## Contributing

1. Create a new branch
2. Make your changes
3. Run tests
4. Submit a pull request
5. Wait for required reviews

## License

[Your License Here] 