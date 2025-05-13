import * as cdk from 'aws-cdk-lib';
import * as kms from 'aws-cdk-lib/aws-kms';
import * as iam from 'aws-cdk-lib/aws-iam';
import { Construct } from 'constructs';
import { BaseConfig } from '../../env/base-config';

export interface KmsConstructProps {
  environment: string;
  config: BaseConfig;
}

export class KmsConstruct extends Construct {
  public readonly key: kms.Key;
  private readonly account: string;

  constructor(scope: Construct, id: string, props: KmsConstructProps) {
    super(scope, id);

    // Get account from stack
    const stack = cdk.Stack.of(this);
    this.account = stack.account;

    // Create KMS key
    this.key = new kms.Key(this, 'Key', {
      alias: `finefinds-${props.environment}-key`,
      description: `KMS key for FineFinds ${props.environment} environment`,
      enableKeyRotation: true,
      pendingWindow: cdk.Duration.days(7),
      removalPolicy: props.environment === 'prod' 
        ? cdk.RemovalPolicy.RETAIN 
        : cdk.RemovalPolicy.DESTROY,
    });

    // Add key policy
    this.key.addToResourcePolicy(
      new iam.PolicyStatement({
        effect: iam.Effect.ALLOW,
        principals: [
          new iam.AccountPrincipal(this.account),
        ],
        actions: [
          'kms:Encrypt',
          'kms:Decrypt',
          'kms:ReEncrypt*',
          'kms:GenerateDataKey*',
          'kms:DescribeKey',
        ],
        resources: ['*'],
      })
    );

    // Allow CloudWatch Logs to use the key
    this.key.addToResourcePolicy(
      new iam.PolicyStatement({
        effect: iam.Effect.ALLOW,
        principals: [
          new iam.ServicePrincipal('logs.amazonaws.com'),
        ],
        actions: [
          'kms:Encrypt*',
          'kms:Decrypt*',
          'kms:ReEncrypt*',
          'kms:GenerateDataKey*',
          'kms:Describe*',
        ],
        resources: ['*'],
        conditions: {
          ArnLike: {
            'kms:EncryptionContext:aws:logs:arn': `arn:aws:logs:${stack.region}:${this.account}:*`,
          },
        },
      })
    );

    // Output key ARN
    new cdk.CfnOutput(this, 'KeyArn', {
      value: this.key.keyArn,
      description: 'KMS Key ARN',
      exportName: `finefinds-${props.environment}-key-arn`,
    });
  }
} 