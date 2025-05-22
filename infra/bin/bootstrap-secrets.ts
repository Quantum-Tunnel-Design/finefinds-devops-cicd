#!/usr/bin/env node
import * as cdk from 'aws-cdk-lib';
import * as secretsmanager from 'aws-cdk-lib/aws-secretsmanager';
import * as kms from 'aws-cdk-lib/aws-kms';
import * as cr from 'aws-cdk-lib/custom-resources';
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

    // Define secret names
    const redisSecretName = `finefinds-${environment}-redis-connection`;
    const githubSecretName = `finefinds-${environment}-github-token`;
    const jwtSecretName = `finefinds-${environment}-jwt-secret`;
    const smtpSecretName = `finefinds-${environment}-smtp-secret`;
    const cognitoSecretName = `finefinds-${environment}-cognito-config`;
    const rdsSecretName = `finefinds-${environment}-rds-connection`;

    // Create or import GitHub token secret
    const githubSecret = new cr.AwsCustomResource(this, 'GitHubToken', {
      onCreate: {
        service: 'SecretsManager',
        action: 'createSecret',
        parameters: {
          Name: githubSecretName,
          Description: 'GitHub token for Amplify apps',
          SecretString: JSON.stringify({
            token: 'placeholder-will-be-updated'
          })
        },
        physicalResourceId: cr.PhysicalResourceId.of(githubSecretName)
      },
      onUpdate: {
        service: 'SecretsManager',
        action: 'updateSecret',
        parameters: {
          SecretId: githubSecretName,
          SecretString: JSON.stringify({
            token: 'placeholder-will-be-updated'
          })
        },
        physicalResourceId: cr.PhysicalResourceId.of(githubSecretName)
      },
      onDelete: {
        service: 'SecretsManager',
        action: 'deleteSecret',
        parameters: {
          SecretId: githubSecretName,
          ForceDeleteWithoutRecovery: true
        }
      },
      policy: cr.AwsCustomResourcePolicy.fromSdkCalls({
        resources: cr.AwsCustomResourcePolicy.ANY_RESOURCE
      })
    });

    // Create or import RDS connection secret
    const rdsSecret = new cr.AwsCustomResource(this, 'RdsConnectionSecret', {
      onCreate: {
        service: 'SecretsManager',
        action: 'createSecret',
        parameters: {
          Name: rdsSecretName,
          Description: 'RDS connection details for the application',
          SecretString: JSON.stringify({
            username: 'placeholder',
            password: 'placeholder',
            engine: 'postgres',
            host: 'placeholder',
            port: 5432,
            dbClusterIdentifier: 'placeholder'
          })
        },
        physicalResourceId: cr.PhysicalResourceId.of(rdsSecretName)
      },
      onUpdate: {
        service: 'SecretsManager',
        action: 'updateSecret',
        parameters: {
          SecretId: rdsSecretName,
          SecretString: JSON.stringify({
            username: 'placeholder',
            password: 'placeholder',
            engine: 'postgres',
            host: 'placeholder',
            port: 5432,
            dbClusterIdentifier: 'placeholder'
          })
        },
        physicalResourceId: cr.PhysicalResourceId.of(rdsSecretName)
      },
      onDelete: {
        service: 'SecretsManager',
        action: 'deleteSecret',
        parameters: {
          SecretId: rdsSecretName,
          ForceDeleteWithoutRecovery: true
        }
      },
      policy: cr.AwsCustomResourcePolicy.fromSdkCalls({
        resources: cr.AwsCustomResourcePolicy.ANY_RESOURCE
      })
    });

    // Create or import Redis connection secret
    const redisSecret = new cr.AwsCustomResource(this, 'RedisConnectionString', {
      onCreate: {
        service: 'SecretsManager',
        action: 'createSecret',
        parameters: {
          Name: redisSecretName,
          Description: 'Redis connection details for the application',
          SecretString: JSON.stringify({
            host: 'placeholder-will-be-updated',
            port: 6379,
            password: 'placeholder-will-be-updated'
          })
        },
        physicalResourceId: cr.PhysicalResourceId.of(redisSecretName)
      },
      onUpdate: {
        service: 'SecretsManager',
        action: 'updateSecret',
        parameters: {
          SecretId: redisSecretName,
          SecretString: JSON.stringify({
            host: 'placeholder-will-be-updated',
            port: 6379,
            password: 'placeholder-will-be-updated'
          })
        },
        physicalResourceId: cr.PhysicalResourceId.of(redisSecretName)
      },
      onDelete: {
        service: 'SecretsManager',
        action: 'deleteSecret',
        parameters: {
          SecretId: redisSecretName,
          ForceDeleteWithoutRecovery: true
        }
      },
      policy: cr.AwsCustomResourcePolicy.fromSdkCalls({
        resources: cr.AwsCustomResourcePolicy.ANY_RESOURCE
      })
    });

    // Create or import JWT secret
    const jwtSecret = new cr.AwsCustomResource(this, 'JwtSecret', {
      onCreate: {
        service: 'SecretsManager',
        action: 'createSecret',
        parameters: {
          Name: jwtSecretName,
          Description: 'JWT secret for application authentication',
          SecretString: JSON.stringify({
            secret: 'placeholder-will-be-updated'
          })
        },
        physicalResourceId: cr.PhysicalResourceId.of(jwtSecretName)
      },
      onUpdate: {
        service: 'SecretsManager',
        action: 'updateSecret',
        parameters: {
          SecretId: jwtSecretName,
          SecretString: JSON.stringify({
            secret: 'placeholder-will-be-updated'
          })
        },
        physicalResourceId: cr.PhysicalResourceId.of(jwtSecretName)
      },
      onDelete: {
        service: 'SecretsManager',
        action: 'deleteSecret',
        parameters: {
          SecretId: jwtSecretName,
          ForceDeleteWithoutRecovery: true
        }
      },
      policy: cr.AwsCustomResourcePolicy.fromSdkCalls({
        resources: cr.AwsCustomResourcePolicy.ANY_RESOURCE
      })
    });

    // Create or import SMTP secret
    const smtpSecret = new cr.AwsCustomResource(this, 'SmtpSecret', {
      onCreate: {
        service: 'SecretsManager',
        action: 'createSecret',
        parameters: {
          Name: smtpSecretName,
          Description: 'SMTP credentials for email sending',
          SecretString: JSON.stringify({
            host: 'placeholder-will-be-updated',
            port: 587,
            username: 'placeholder-will-be-updated',
            password: 'placeholder-will-be-updated'
          })
        },
        physicalResourceId: cr.PhysicalResourceId.of(smtpSecretName)
      },
      onUpdate: {
        service: 'SecretsManager',
        action: 'updateSecret',
        parameters: {
          SecretId: smtpSecretName,
          SecretString: JSON.stringify({
            host: 'placeholder-will-be-updated',
            port: 587,
            username: 'placeholder-will-be-updated',
            password: 'placeholder-will-be-updated'
          })
        },
        physicalResourceId: cr.PhysicalResourceId.of(smtpSecretName)
      },
      onDelete: {
        service: 'SecretsManager',
        action: 'deleteSecret',
        parameters: {
          SecretId: smtpSecretName,
          ForceDeleteWithoutRecovery: true
        }
      },
      policy: cr.AwsCustomResourcePolicy.fromSdkCalls({
        resources: cr.AwsCustomResourcePolicy.ANY_RESOURCE
      })
    });

    // Create or import Cognito config secret
    const cognitoSecret = new cr.AwsCustomResource(this, 'CognitoConfig', {
      onCreate: {
        service: 'SecretsManager',
        action: 'createSecret',
        parameters: {
          Name: cognitoSecretName,
          Description: 'Cognito configuration for the application',
          SecretString: JSON.stringify({
            clientUserPoolId: 'placeholder-will-be-updated',
            clientUserPoolClientId: 'placeholder-will-be-updated',
            adminUserPoolId: 'placeholder-will-be-updated',
            adminUserPoolClientId: 'placeholder-will-be-updated'
          })
        },
        physicalResourceId: cr.PhysicalResourceId.of(cognitoSecretName)
      },
      onUpdate: {
        service: 'SecretsManager',
        action: 'updateSecret',
        parameters: {
          SecretId: cognitoSecretName,
          SecretString: JSON.stringify({
            clientUserPoolId: 'placeholder-will-be-updated',
            clientUserPoolClientId: 'placeholder-will-be-updated',
            adminUserPoolId: 'placeholder-will-be-updated',
            adminUserPoolClientId: 'placeholder-will-be-updated'
          })
        },
        physicalResourceId: cr.PhysicalResourceId.of(cognitoSecretName)
      },
      onDelete: {
        service: 'SecretsManager',
        action: 'deleteSecret',
        parameters: {
          SecretId: cognitoSecretName,
          ForceDeleteWithoutRecovery: true
        }
      },
      policy: cr.AwsCustomResourcePolicy.fromSdkCalls({
        resources: cr.AwsCustomResourcePolicy.ANY_RESOURCE
      })
    });

    // Import the secrets for reference
    const redisConnectionSecret = secretsmanager.Secret.fromSecretNameV2(this, 'ImportedRedisConnectionString', redisSecretName);
    const jwtSecretRef = secretsmanager.Secret.fromSecretNameV2(this, 'ImportedJwtSecret', jwtSecretName);
    const smtpSecretRef = secretsmanager.Secret.fromSecretNameV2(this, 'ImportedSmtpSecret', smtpSecretName);
    const githubSecretRef = secretsmanager.Secret.fromSecretNameV2(this, 'ImportedGitHubToken', githubSecretName);
    const cognitoSecretRef = secretsmanager.Secret.fromSecretNameV2(this, 'ImportedCognitoConfig', cognitoSecretName);
    const rdsSecretRef = secretsmanager.Secret.fromSecretNameV2(this, 'ImportedRdsSecret', rdsSecretName);

    // Apply RETAIN removal policy to the custom resources
    redisSecret.node.addDependency(redisConnectionSecret);
    jwtSecret.node.addDependency(jwtSecretRef);
    smtpSecret.node.addDependency(smtpSecretRef);
    githubSecret.node.addDependency(githubSecretRef);
    cognitoSecret.node.addDependency(cognitoSecretRef);

    // Output secret ARNs
    new cdk.CfnOutput(this, 'RedisSecretArn', {
      value: redisConnectionSecret.secretArn,
      description: 'Redis secret ARN',
      exportName: `finefinds-${environment}-redis-secret-arn`,
    });

    new cdk.CfnOutput(this, 'JwtSecretArn', {
      value: jwtSecretRef.secretArn,
      description: 'JWT secret ARN',
      exportName: `finefinds-${environment}-jwt-secret-arn`,
    });

    new cdk.CfnOutput(this, 'SmtpSecretArn', {
      value: smtpSecretRef.secretArn,
      description: 'SMTP secret ARN',
      exportName: `finefinds-${environment}-smtp-secret-arn`,
    });

    new cdk.CfnOutput(this, 'GitHubTokenArn', {
      value: githubSecretRef.secretArn,
      description: 'GitHub Token secret ARN',
      exportName: `finefinds-${environment}-github-token-secret-arn`,
    });

    new cdk.CfnOutput(this, 'CognitoConfigArn', {
      value: cognitoSecretRef.secretArn,
      description: 'Cognito configuration secret ARN',
      exportName: `finefinds-${environment}-cognito-config-arn`,
    });

    new cdk.CfnOutput(this, 'RdsSecretArn', {
      value: rdsSecretRef.secretArn,
      description: 'RDS Connection secret ARN',
      exportName: `finefinds-${environment}-rds-connection-secret-arn`,
    });
  }
}

// Create app and instantiate stack
const app = new cdk.App();

// Get environment and qualifier from context
const environment = app.node.tryGetContext('environment') || 'dev';
const qualifier = app.node.tryGetContext('qualifier') || 'ffdev';

// Create custom synthesizer with our qualifier
const customSynthesizer = new cdk.DefaultStackSynthesizer({
  qualifier: qualifier,
});

new SecretsBootstrapStack(app, `finefinds-secrets-bootstrap-${environment}`, {
  env: {
    account: process.env.CDK_DEFAULT_ACCOUNT,
    region: process.env.CDK_DEFAULT_REGION
  },
  description: 'Stack for bootstrapping secrets required by finefinds infrastructure',
  synthesizer: customSynthesizer,
}); 