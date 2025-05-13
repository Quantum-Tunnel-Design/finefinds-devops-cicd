#!/usr/bin/env node
import * as cdk from 'aws-cdk-lib';
import * as secretsmanager from 'aws-cdk-lib/aws-secretsmanager';
import * as kms from 'aws-cdk-lib/aws-kms';
import { Construct } from 'constructs';

/**
 * Stack for bootstrapping secrets in new environments
 * This stack creates the initial secrets needed before the main infrastructure is deployed
 */
class SecretsBootstrapStack extends cdk.Stack {
  constructor(scope: Construct, id: string, props?: cdk.StackProps) {
    super(scope, id, props);

    // Get environment name from context or use 'dev' as default
    const environment = this.node.tryGetContext('environment') || 'dev';
    
    // Create a KMS key for encrypting the secrets
    const key = new kms.Key(this, 'BootstrapKey', {
      alias: `alias/finefinds-${environment}-bootstrap`,
      enableKeyRotation: true,
      description: `Key for bootstrapping ${environment} environment secrets`,
      removalPolicy: cdk.RemovalPolicy.RETAIN, // Important: Never delete this key
    });

    // Create the database connection secret with initial placeholder values
    const dbConnectionStringSecret = new secretsmanager.Secret(this, 'DbConnectionString', {
      secretName: `finefinds-${environment}-db-connection`,
      description: 'Database connection string for the application',
      encryptionKey: key,
      generateSecretString: {
        secretStringTemplate: JSON.stringify({
          dbName: 'finefinds',
          engine: 'postgres',
          host: 'placeholder-will-be-updated', // This will be updated by the main stack
          port: 5432,
          username: 'postgres',
        }),
        generateStringKey: 'password',
        excludePunctuation: false,
        passwordLength: 32,
      },
    });
    
    // Apply a RETAIN removal policy so the secret is not deleted if this stack is destroyed
    dbConnectionStringSecret.applyRemovalPolicy(cdk.RemovalPolicy.RETAIN);

    // Create a Redis connection secret with initial placeholder values
    const redisConnectionSecret = new secretsmanager.Secret(this, 'RedisConnectionString', {
      secretName: `finefinds-${environment}-redis-connection`,
      description: 'Redis connection details for the application',
      encryptionKey: key,
      generateSecretString: {
        secretStringTemplate: JSON.stringify({
          host: 'placeholder-will-be-updated', // This will be updated by the main stack
          port: 6379,
        }),
        generateStringKey: 'password',
        excludePunctuation: false,
        passwordLength: 32,
      },
    });
    
    // Apply a RETAIN removal policy so the secret is not deleted if this stack is destroyed
    redisConnectionSecret.applyRemovalPolicy(cdk.RemovalPolicy.RETAIN);

    // Output the secret ARNs for reference
    new cdk.CfnOutput(this, 'DbConnectionSecretArn', {
      value: dbConnectionStringSecret.secretArn,
      description: 'ARN of the database connection secret',
      exportName: `finefinds-${environment}-bootstrap-db-secret-arn`,
    });

    new cdk.CfnOutput(this, 'RedisConnectionSecretArn', {
      value: redisConnectionSecret.secretArn,
      description: 'ARN of the Redis connection secret',
      exportName: `finefinds-${environment}-bootstrap-redis-secret-arn`,
    });
  }
}

// Create app and instantiate stack
const app = new cdk.App();
new SecretsBootstrapStack(app, 'FineFinds-Secrets-Bootstrap', {
  env: {
    account: process.env.CDK_DEFAULT_ACCOUNT,
    region: process.env.CDK_DEFAULT_REGION
  },
  description: 'Stack for bootstrapping secrets required by FineFinds infrastructure'
}); 