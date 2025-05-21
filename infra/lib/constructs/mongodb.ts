import * as cdk from 'aws-cdk-lib';
import * as secretsmanager from 'aws-cdk-lib/aws-secretsmanager';
import * as iam from 'aws-cdk-lib/aws-iam';
import { Construct } from 'constructs';
import { BaseConfig } from '../../env/base-config';

export interface MongoDbConstructProps {
  environment: string;
  config: BaseConfig;
  kmsKey: cdk.aws_kms.Key;
}

export class MongoDbConstruct extends Construct {
  public readonly connectionString: secretsmanager.Secret;

  constructor(scope: Construct, id: string, props: MongoDbConstructProps) {
    super(scope, id);

    // Create secret for MongoDB connection string
    this.connectionString = new secretsmanager.Secret(this, 'MongoDbConnectionString', {
      secretName: `finefinds-${props.environment}-mongodb-connection`,
      description: 'MongoDB Atlas connection string',
      encryptionKey: props.kmsKey,
      generateSecretString: {
        secretStringTemplate: JSON.stringify({
          username: 'finefinds',
          database: 'finefinds',
        }),
        generateStringKey: 'password',
        excludePunctuation: false,
        passwordLength: 32,
      },
    });

    // Create IAM policy for ECS tasks to access MongoDB
    const mongoPolicy = new iam.PolicyStatement({
      effect: iam.Effect.ALLOW,
      actions: [
        'secretsmanager:GetSecretValue',
        'secretsmanager:DescribeSecret',
      ],
      resources: [this.connectionString.secretArn],
    });

    // Output MongoDB connection string ARN
    new cdk.CfnOutput(this, 'MongoDBConnectionStringArn', {
      value: this.connectionString.secretArn,
      description: 'MongoDB connection string ARN',
      exportName: `finefinds-${props.environment}-mongodb-secret-arn`,
    });
  }
} 