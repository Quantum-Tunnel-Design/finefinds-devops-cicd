import * as cdk from 'aws-cdk-lib';
import * as secretsmanager from 'aws-cdk-lib/aws-secretsmanager';
import * as iam from 'aws-cdk-lib/aws-iam';
import * as kms from 'aws-cdk-lib/aws-kms';
import { Construct } from 'constructs';
import { BaseConfig } from '../../env/base-config';

export interface SecretsConstructProps {
  environment: string;
  config: BaseConfig;
  kmsKey: kms.Key;
}

export class SecretsConstruct extends Construct {
  public readonly databaseSecret: secretsmanager.ISecret;
  public readonly redisSecret: secretsmanager.ISecret;
  public readonly opensearchSecret: secretsmanager.ISecret;
  public readonly jwtSecret: secretsmanager.ISecret;
  public readonly smtpSecret: secretsmanager.ISecret;
  public readonly cognitoConfigSecret: secretsmanager.ISecret;

  constructor(scope: Construct, id: string, props: SecretsConstructProps) {
    super(scope, id);

    // Create database secret
    this.databaseSecret = secretsmanager.Secret.fromSecretNameV2(this, 'DatabaseSecret', `finefinds-${props.environment}-rds-connection`);

    // Create Redis secret
    this.redisSecret = secretsmanager.Secret.fromSecretNameV2(this, 'RedisSecret', `finefinds-${props.environment}-redis-connection`);

    // Create OpenSearch secret
    this.opensearchSecret = secretsmanager.Secret.fromSecretNameV2(this, 'OpenSearchSecret', `finefinds-${props.environment}-opensearch-admin-password`);

    // Create JWT secret
    this.jwtSecret = secretsmanager.Secret.fromSecretNameV2(this, 'JwtSecret', `finefinds-${props.environment}-jwt-secret`);

    // Create SMTP secret
    this.smtpSecret = secretsmanager.Secret.fromSecretNameV2(this, 'SmtpSecret', `finefinds-${props.environment}-smtp-secret`);

    // Create Cognito Config Secret
    this.cognitoConfigSecret = new secretsmanager.Secret(this, 'CognitoConfigSecret', {
      secretName: `finefinds-${props.environment}-cognito-config`,
      description: `Cognito configuration for FineFinds ${props.environment} environment`,
      encryptionKey: props.kmsKey,
    });
    this.cognitoConfigSecret.applyRemovalPolicy(props.environment === 'prod' ? cdk.RemovalPolicy.RETAIN : cdk.RemovalPolicy.DESTROY);

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
        this.cognitoConfigSecret.secretArn,
      ],
    });
  }
} 