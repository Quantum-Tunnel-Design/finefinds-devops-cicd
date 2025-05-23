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
  public readonly opensearchSecret?: secretsmanager.ISecret;
  public readonly jwtSecret: secretsmanager.ISecret;
  public readonly smtpSecret: secretsmanager.ISecret;
  public readonly cognitoConfigSecret: secretsmanager.ISecret;
  public readonly taskRolePolicy: iam.PolicyStatement;

  constructor(scope: Construct, id: string, props: SecretsConstructProps) {
    super(scope, id);

    // Create database secret
    this.databaseSecret = secretsmanager.Secret.fromSecretNameV2(this, 'DatabaseSecret', `finefinds-${props.environment}-rds-connection`);

    // Create Redis secret
    this.redisSecret = secretsmanager.Secret.fromSecretNameV2(this, 'RedisSecret', `finefinds-${props.environment}-redis-connection`);

    // Create OpenSearch secret only for prod environment
    if (props.environment === 'prod') {
      this.opensearchSecret = secretsmanager.Secret.fromSecretNameV2(this, 'OpenSearchSecret', `finefinds-${props.environment}-opensearch-admin-password`);
    }

    // Create JWT secret
    this.jwtSecret = secretsmanager.Secret.fromSecretNameV2(this, 'JwtSecret', `finefinds-${props.environment}-jwt-secret`);

    // Create SMTP secret
    this.smtpSecret = secretsmanager.Secret.fromSecretNameV2(this, 'SmtpSecret', `finefinds-${props.environment}-smtp-secret`);

    // Import Cognito Config Secret
    this.cognitoConfigSecret = secretsmanager.Secret.fromSecretNameV2(this, 'CognitoConfigSecret', `finefinds-${props.environment}-cognito-config`);

    // Create IAM policy for ECS tasks to access secrets
    const secretArns = [
      this.databaseSecret.secretFullArn,
      this.redisSecret.secretFullArn,
      this.opensearchSecret?.secretFullArn, // Optional chaining for opensearchSecret
      this.jwtSecret.secretFullArn,
      this.smtpSecret.secretFullArn,
      this.cognitoConfigSecret.secretFullArn,
    ].filter(arn => arn !== undefined) as string[]; // Filter out undefined and assert as string[]

    this.taskRolePolicy = new iam.PolicyStatement({
      effect: iam.Effect.ALLOW,
      actions: [
        'secretsmanager:GetSecretValue',
        'secretsmanager:DescribeSecret',
      ],
      resources: secretArns, // Use the filtered list
    });

    // Re-add Diagnostic output
    if (props.environment === 'dev') {
      new cdk.CfnOutput(this, 'DebugJwtSecretArn', {
        value: this.jwtSecret.secretFullArn || 'undefined-jwt-arn',
        description: 'DEBUG: JWT Secret Full ARN for dev',
      });
    }
  }
} 