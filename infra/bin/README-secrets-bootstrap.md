# Secrets Bootstrap Process

This process is designed to create the necessary secrets for a new FineFinds environment before deploying the main infrastructure.

## When to Use

Use the secrets bootstrap process when:

1. Setting up a brand new environment (dev, qa, uat, prod)
2. Recovering from a situation where secrets were accidentally deleted
3. Migrating to a new AWS account

## How It Works

The bootstrap process creates:

- A KMS key for encrypting secrets
- Initial database connection secret with placeholder values
- Initial Redis connection secret with placeholder values

All resources are created with `RemovalPolicy.RETAIN` to ensure they aren't accidentally deleted.

## Usage

To bootstrap secrets for a new environment:

```bash
# For dev environment (default)
npm run bootstrap-secrets

# For a specific environment (e.g., uat)
npm run bootstrap-secrets -- -c environment=uat

# For production
npm run bootstrap-secrets -- -c environment=prod
```

## CI/CD Integration

To integrate with your CI/CD pipeline, add this step before deploying the main infrastructure:

```yaml
jobs:
  deploy:
    steps:
      # Other steps...
      
      - name: Bootstrap Secrets (if new environment)
        if: ${{ env.IS_NEW_ENVIRONMENT == 'true' }}
        run: |
          cd infra
          npm run bootstrap-secrets -- -c environment=${{ env.ENVIRONMENT }}
      
      - name: Deploy Main Infrastructure
        run: |
          cd infra
          npm run cdk deploy
      
      # Other steps...
```

## Verifying Success

After running the bootstrap process, you should see the output with the ARNs of the created secrets. These secrets will be empty or contain placeholder values until the main infrastructure is deployed, which will update them with real connection information.

## Troubleshooting

If you encounter errors like `AlreadyExists` for secrets, it means the secrets already exist in the account. This is not an issue - it means your environment is already set up correctly. You can proceed with deploying the main infrastructure.

For a complete reset, you would need to delete the existing secrets first:

```bash
# Be very careful with these commands in production!
aws secretsmanager delete-secret --secret-id finefinds-<env>-db-connection --force-delete-without-recovery
aws secretsmanager delete-secret --secret-id finefinds-<env>-redis-connection --force-delete-without-recovery
``` 