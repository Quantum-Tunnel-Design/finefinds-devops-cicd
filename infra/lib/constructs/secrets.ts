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

    const removalPolicy = props.environment === 'prod' ? cdk.RemovalPolicy.RETAIN : cdk.RemovalPolicy.DESTROY;

    // Secrets for existing resources (placeholders to be populated or existing names)
    this.databaseSecret = secretsmanager.Secret.fromSecretNameV2(this, 'DatabaseSecret', `finefinds-${props.environment}-rds-connection`);
    this.redisSecret = secretsmanager.Secret.fromSecretNameV2(this, 'RedisSecret', `finefinds-${props.environment}-redis-connection`);
    this.cognitoConfigSecret = secretsmanager.Secret.fromSecretNameV2(this, 'CognitoConfigSecret', `finefinds-${props.environment}-cognito-config`);

    if (props.environment === 'prod') {
      this.opensearchSecret = secretsmanager.Secret.fromSecretNameV2(this, 'OpenSearchSecret', `finefinds-${props.environment}-opensearch-admin-password`);
    }

    // Secrets created and managed by this CDK stack
    this.jwtSecret = new secretsmanager.Secret(this, 'JwtSecret', {
      secretName: `finefinds-${props.environment}-jwt-secret`,
      description: `JWT secret for FineFinds ${props.environment}`,
      generateSecretString: {
        secretStringTemplate: JSON.stringify({ secret: "please-replace-this-jwt-secret-in-secrets-manager" }),
        generateStringKey: "placeholderKey", // Required by type, but template is used
      },
      encryptionKey: props.kmsKey,
      removalPolicy: removalPolicy,
    });

    this.smtpSecret = new secretsmanager.Secret(this, 'SmtpSecret', {
      secretName: `finefinds-${props.environment}-smtp-secret`,
      description: `SMTP secret for FineFinds ${props.environment}`,
      generateSecretString: { // Placeholder for SMTP credentials if managed here
        secretStringTemplate: JSON.stringify({
          host: "smtp.example.com",
          port: 587,
          username: "user@example.com",
          password: "replace-smtp-password"
        }),
        generateStringKey: "placeholderKey",
      },
      encryptionKey: props.kmsKey,
      removalPolicy: removalPolicy,
    });

    // IAM policy for ECS tasks to access secrets
    const secretArns = [
      this.databaseSecret.secretArn,
      this.redisSecret.secretArn,
      this.jwtSecret.secretArn,
      this.smtpSecret.secretArn,
      this.cognitoConfigSecret.secretArn,
    ];

    if (this.opensearchSecret) { // Check if opensearchSecret is defined
      secretArns.push(this.opensearchSecret.secretArn);
    }

    this.taskRolePolicy = new iam.PolicyStatement({
      effect: iam.Effect.ALLOW,
      actions: [
        'secretsmanager:GetSecretValue',
        'secretsmanager:DescribeSecret',
      ],
      resources: secretArns,
    });
  }
} 