import * as cdk from 'aws-cdk-lib';
import * as secretsmanager from 'aws-cdk-lib/aws-secretsmanager';
import * as iam from 'aws-cdk-lib/aws-iam';
import * as kms from 'aws-cdk-lib/aws-kms';
import { Construct } from 'constructs';
import { BaseConfig } from '../../env/base-config';

export interface SecretsConstructProps {
  environment: string;
  config: BaseConfig;
  kmsKey: kms.IKey;
}

export class SecretsConstruct extends Construct {
  public readonly databaseSecret: secretsmanager.Secret;
  public readonly redisSecret: secretsmanager.Secret;
  public readonly opensearchSecret: secretsmanager.Secret;
  public readonly jwtSecret: secretsmanager.Secret;
  public readonly smtpSecret: secretsmanager.Secret;

  constructor(scope: Construct, id: string, props: SecretsConstructProps) {
    super(scope, id);

    // Create database secret
    this.databaseSecret = new secretsmanager.Secret(this, 'DatabaseSecret', {
      secretName: `${props.config.environment}/database`,
      description: 'Database credentials',
      encryptionKey: props.kmsKey,
      generateSecretString: {
        secretStringTemplate: JSON.stringify({
          username: 'admin',
        }),
        generateStringKey: 'password',
        excludePunctuation: false,
        passwordLength: 16,
      },
    });

    // Create Redis secret
    this.redisSecret = new secretsmanager.Secret(this, 'RedisSecret', {
      secretName: `${props.config.environment}/redis`,
      description: 'Redis connection details',
      encryptionKey: props.kmsKey,
      generateSecretString: {
        secretStringTemplate: JSON.stringify({
          host: 'localhost', // This will be updated after Redis cluster creation
          port: 6379,
          username: 'default',
        }),
        generateStringKey: 'password',
        excludePunctuation: false,
        passwordLength: 16,
      },
    });

    // Create OpenSearch secret
    this.opensearchSecret = new secretsmanager.Secret(this, 'OpenSearchSecret', {
      secretName: `finefinds-${props.environment}-opensearch-admin-password`,
      description: 'OpenSearch admin password for FineFinds application',
      encryptionKey: props.kmsKey,
      generateSecretString: {
        secretStringTemplate: JSON.stringify({}),
        generateStringKey: 'password',
        excludePunctuation: false,
        passwordLength: 32,
      },
    });

    // Create JWT secret
    this.jwtSecret = new secretsmanager.Secret(this, 'JwtSecret', {
      secretName: `finefinds-${props.environment}-jwt`,
      description: 'JWT signing key for FineFinds application',
      encryptionKey: props.kmsKey,
      generateSecretString: {
        secretStringTemplate: JSON.stringify({}),
        generateStringKey: 'key',
        excludePunctuation: false,
        passwordLength: 64,
      },
    });

    // Create SMTP secret
    this.smtpSecret = new secretsmanager.Secret(this, 'SmtpSecret', {
      secretName: `finefinds-${props.environment}-smtp`,
      description: 'SMTP credentials for FineFinds application',
      encryptionKey: props.kmsKey,
      generateSecretString: {
        secretStringTemplate: JSON.stringify({
          host: props.config.smtp.host,
          port: props.config.smtp.port,
          username: props.config.smtp.username,
        }),
        generateStringKey: 'password',
        excludePunctuation: false,
        passwordLength: 32,
      },
    });

    // Create IAM policy for ECS tasks to access secrets
    const secretsPolicy = new iam.PolicyStatement({
      effect: iam.Effect.ALLOW,
      actions: [
        'secretsmanager:GetSecretValue',
        'secretsmanager:DescribeSecret',
      ],
      resources: [
        this.databaseSecret.secretArn,
        this.redisSecret.secretArn,
        this.opensearchSecret.secretArn,
        this.jwtSecret.secretArn,
        this.smtpSecret.secretArn,
      ],
    });

    // Output secret ARNs
    new cdk.CfnOutput(this, 'DatabaseSecretArn', {
      value: this.databaseSecret.secretArn,
      description: 'Database secret ARN',
      exportName: `finefinds-${props.config.environment}-database-secret-arn`,
    });

    new cdk.CfnOutput(this, 'RedisSecretArn', {
      value: this.redisSecret.secretArn,
      description: 'Redis secret ARN',
      exportName: `finefinds-${props.config.environment}-redis-secret-arn`,
    });

    new cdk.CfnOutput(this, 'OpenSearchSecretArn', {
      value: this.opensearchSecret.secretArn,
      description: 'OpenSearch Secret ARN',
      exportName: `finefinds-${props.environment}-opensearch-secret-arn`,
    });

    new cdk.CfnOutput(this, 'JwtSecretArn', {
      value: this.jwtSecret.secretArn,
      description: 'JWT Secret ARN',
      exportName: `finefinds-${props.environment}-jwt-secret-arn`,
    });

    new cdk.CfnOutput(this, 'SmtpSecretArn', {
      value: this.smtpSecret.secretArn,
      description: 'SMTP Secret ARN',
      exportName: `finefinds-${props.environment}-smtp-secret-arn`,
    });
  }
} 