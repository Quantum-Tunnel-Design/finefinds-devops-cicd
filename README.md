# FineFinds DevOps & CI/CD

This repository contains the infrastructure and CI/CD configuration for FineFinds.

## Prerequisites

- GitHub CLI (`gh`)
- AWS CLI
- Terraform
- Node.js and npm

## Environment Setup

### Branch to Environment Mapping

The repository uses a specific mapping between Git branches and deployment environments:

| Branch Name | Environment Name | Purpose |
|-------------|------------------|---------|
| `main`      | `prod`          | Production environment |
| `staging`   | `staging`       | Pre-production testing |
| `dev`       | `dev`           | Development environment |
| `qa`        | `qa`            | Quality assurance testing |
| `sandbox`   | `sandbox`       | Experimental features |

**Note**: While the main branch is named `main`, it maps to the `prod` environment in all configurations. This is important to understand when working with:
- GitHub Environments
- AWS IAM Roles
- Terraform State
- Deployment Workflows

### Environment Validation

All scripts include validation to ensure:
1. Only valid branch names are used
2. Environment names are consistent across all tools
3. Branch-to-environment mappings are maintained

## Initial Setup

1. **GitHub Authentication**
   ```bash
   gh auth login
   ```

2. **AWS OIDC Setup**
   ```bash
   update ENVs.
   Coordinate with dev-ops team for credential access
   ```

3. **GitHub Secrets Setup**
   ```bash
   # Set SonarQube credentials
   Coordinate with dev-ops team for credential access

   # Set AWS credentials for each environment
   Coordinate with dev-ops team for credential access

   ./scripts/setup-github-secrets.sh
   ```

4. **Environment Protection Rules**
   ```bash
   ./scripts/setup-environment-protection.sh
   ```

## Environment-Specific Configurations

### Production (main branch → prod environment)
- Quality Gate: Strict
- Backup Retention: 30 days
- Protection Rules:
  - 30-minute wait timer
  - 2 required reviewers
  - Branch protection enabled

### Staging
- Quality Gate: Moderate
- Backup Retention: 14 days
- Protection Rules:
  - 15-minute wait timer
  - 1 required reviewer
  - Branch protection enabled

### Development
- Quality Gate: Basic
- Backup Retention: 7 days
- Protection Rules:
  - No wait timer
  - No required reviewers
  - Branch protection enabled

### QA
- Quality Gate: Basic
- Backup Retention: 7 days
- Protection Rules:
  - No wait timer
  - No required reviewers
  - Branch protection enabled

### Sandbox
- Quality Gate: None
- Backup Retention: 3 days
- Protection Rules:
  - No wait timer
  - No required reviewers
  - Branch protection enabled

## GitHub Actions Workflows

### Terraform Deployment
- Triggered on push to protected branches
- Uses AWS OIDC for authentication
- Environment-specific deployments
- Branch-to-environment mapping is handled automatically

### SonarQube Scan
- Triggered on pull requests and pushes
- Quality gates are environment-specific
- Results are stored in SonarQube server

## Security Considerations

### AWS Authentication
- Uses OIDC for GitHub Actions
- Environment-specific IAM roles
- Role names follow the environment mapping (e.g., `github-actions-prod` for main branch)

### GitHub Secrets
- Environment-specific secrets
- Secrets are automatically mapped to the correct environment
- Sensitive values are encrypted

### Environment Protection
- Branch protection rules
- Environment-specific wait timers
- Required reviewers based on environment

## Maintenance

### Rotating Secrets
1. Generate new secrets
2. Update GitHub secrets using the setup script
3. Verify deployments still work

### Adding New Environments
1. Add new branch-to-environment mapping in all scripts
2. Create new environment in GitHub
3. Set up environment-specific secrets
4. Configure protection rules

## Troubleshooting

### Common Issues

1. **Environment Name Mismatch**
   - Error: "Environment not found"
   - Solution: Verify branch-to-environment mapping in scripts

2. **IAM Role Issues**
   - Error: "Role not found"
   - Solution: Check role names follow environment mapping

3. **Secret Access Issues**
   - Error: "Secret not found"
   - Solution: Verify secrets are set for correct environment

### Validation Errors

If you encounter validation errors:
1. Check the branch name is valid
2. Verify environment mapping is correct
3. Ensure all required variables are set

## Support

For issues and support, please contact the DevOps team. 