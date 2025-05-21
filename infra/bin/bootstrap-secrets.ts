#!/usr/bin/env node
import * as cdk from 'aws-cdk-lib';
import * as secretsmanager from 'aws-cdk-lib/aws-secretsmanager';
import * as kms from 'aws-cdk-lib/aws-kms';
import * as cr from 'aws-cdk-lib/custom-resources';
import * as lambda from 'aws-cdk-lib/aws-lambda';
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
    const dbSecretName = `finefinds-${environment}-rds-connection`;
    const redisSecretName = `finefinds-${environment}-redis-connection`;
    const githubSecretName = `finefinds-${environment}-github-token`;
    const jwtSecretName = `finefinds-${environment}-jwt-secret`;
    const smtpSecretName = `finefinds-${environment}-smtp-secret`;

    // Create a custom resource provider for handling secret creation/import
    const secretProvider = new cr.Provider(this, 'SecretProvider', {
      onEventHandler: new lambda.Function(this, 'SecretHandler', {
        runtime: lambda.Runtime.NODEJS_18_X,
        handler: 'index.handler',
        code: lambda.Code.fromInline(`
          const AWS = require('aws-sdk');
          const secretsManager = new AWS.SecretsManager();
          
          exports.handler = async (event) => {
            const { secretName, secretValue, description } = event.ResourceProperties;
            
            try {
              // Try to get the secret first
              await secretsManager.describeSecret({ SecretId: secretName }).promise();
              console.log('Secret already exists:', secretName);
              return { PhysicalResourceId: secretName };
            } catch (error) {
              if (error.code === 'ResourceNotFoundException') {
                // Create the secret if it doesn't exist
                const response = await secretsManager.createSecret({
                  Name: secretName,
                  Description: description,
                  SecretString: JSON.stringify(secretValue)
                }).promise();
                console.log('Created new secret:', secretName);
                return { PhysicalResourceId: response.Name };
              }
              throw error;
            }
          }
        `),
        timeout: cdk.Duration.seconds(30),
      }),
    });

    // Create or import database connection secret
    const dbSecret = new cr.AwsCustomResource(this, 'DbConnectionString', {
      onCreate: {
        service: 'SecretsManager',
        action: 'describeSecret',
        parameters: {
          SecretId: dbSecretName
        },
        physicalResourceId: cr.PhysicalResourceId.of(dbSecretName)
      },
      onUpdate: {
        service: 'SecretsManager',
        action: 'updateSecret',
        parameters: {
          SecretId: dbSecretName,
          SecretString: JSON.stringify({
            dbName: 'finefinds',
            engine: 'postgres',
            host: 'placeholder-will-be-updated',
            port: 5432,
            username: 'postgres',
            password: 'placeholder-will-be-updated'
          })
        },
        physicalResourceId: cr.PhysicalResourceId.of(dbSecretName)
      },
      onDelete: {
        service: 'SecretsManager',
        action: 'deleteSecret',
        parameters: {
          SecretId: dbSecretName,
          ForceDeleteWithoutRecovery: true
        }
      },
      policy: cr.AwsCustomResourcePolicy.fromSdkCalls({
        resources: cr.AwsCustomResourcePolicy.ANY_RESOURCE
      })
    });

    // Create or import GitHub token secret
    const githubSecret = new cr.AwsCustomResource(this, 'GitHubToken', {
      onCreate: {
        service: 'SecretsManager',
        action: 'describeSecret',
        parameters: {
          SecretId: githubSecretName
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

    // Create or import Redis connection secret
    const redisSecret = new cr.AwsCustomResource(this, 'RedisConnectionString', {
      onCreate: {
        service: 'SecretsManager',
        action: 'describeSecret',
        parameters: {
          SecretId: redisSecretName
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
        action: 'describeSecret',
        parameters: {
          SecretId: jwtSecretName
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
        action: 'describeSecret',
        parameters: {
          SecretId: smtpSecretName
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

    // Import the secrets for reference
    const dbConnectionStringSecret = secretsmanager.Secret.fromSecretNameV2(this, 'ImportedDbConnectionString', dbSecretName);
    const githubTokenSecret = secretsmanager.Secret.fromSecretNameV2(this, 'ImportedGitHubToken', githubSecretName);
    const redisConnectionSecret = secretsmanager.Secret.fromSecretNameV2(this, 'ImportedRedisConnectionString', redisSecretName);
    const jwtSecretRef = secretsmanager.Secret.fromSecretNameV2(this, 'ImportedJwtSecret', jwtSecretName);
    const smtpSecretRef = secretsmanager.Secret.fromSecretNameV2(this, 'ImportedSmtpSecret', smtpSecretName);

    // Apply RETAIN removal policy to the custom resources
    dbSecret.node.addDependency(dbConnectionStringSecret);
    githubSecret.node.addDependency(githubTokenSecret);
    redisSecret.node.addDependency(redisConnectionSecret);
    jwtSecret.node.addDependency(jwtSecretRef);
    smtpSecret.node.addDependency(smtpSecretRef);
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