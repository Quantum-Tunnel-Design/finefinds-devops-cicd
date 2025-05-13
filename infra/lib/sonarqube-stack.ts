import * as cdk from 'aws-cdk-lib';
import { Construct } from 'constructs';
import { BaseConfig } from '../env/base-config';
import { VpcConstruct } from './constructs/vpc';
import { SonarQubeConstruct } from './constructs/sonarqube';
import { KmsConstruct } from './constructs/kms';
import { IamConstruct } from './constructs/iam';
import { SecretsConstruct } from './constructs/secrets';
import * as secretsmanager from 'aws-cdk-lib/aws-secretsmanager';

export interface FineFindsSonarQubeStackProps extends cdk.StackProps {
  config: BaseConfig;
}

export class FineFindsSonarQubeStack extends cdk.Stack {
  constructor(scope: Construct, id: string, props: FineFindsSonarQubeStackProps) {
    super(scope, id, props);

    // Create KMS key for encryption
    const kms = new KmsConstruct(this, 'Kms', {
      environment: props.config.environment,
      config: props.config,
    });

    // Create VPC
    const vpc = new VpcConstruct(this, 'Vpc', {
      environment: props.config.environment,
      config: props.config,
    });

    // Create IAM roles
    const iam = new IamConstruct(this, 'Iam', {
      environment: props.config.environment,
      config: props.config,
    });

    // Create Secrets
    const secrets = new SecretsConstruct(this, 'Secrets', {
      environment: props.config.environment,
      config: props.config,
      kmsKey: kms.key,
    });

    // Create SonarQube
    const sonarqube = new SonarQubeConstruct(this, 'SonarQube', {
      environment: props.config.environment,
      config: props.config,
      vpc: vpc.vpc,
      kmsKey: kms.key,
      taskRole: iam.ecsTaskRole,
      executionRole: iam.ecsExecutionRole,
    });

    // Create SonarQube admin token secret
    const adminTokenSecret = new secretsmanager.Secret(this, 'SonarQubeAdminTokenSecret', {
      secretName: `finefinds/${props.config.environment}/sonarqube/admin-token`,
      description: 'SonarQube Admin Token',
      encryptionKey: kms.key,
      generateSecretString: {
        excludePunctuation: true,
        includeSpace: false,
        passwordLength: 20,
      },
    });

    // Output the secret ARN for reference in CI/CD pipelines
    const adminTokenOutput = new cdk.CfnOutput(this, 'SonarQubeAdminToken', {
      value: adminTokenSecret.secretArn,
      description: 'SonarQube Admin Token Secret ARN',
      exportName: `finefinds-${props.config.environment}-sonarqube-admin-token-arn`,
    });

    // Add tags to all resources
    cdk.Tags.of(this).add('Environment', props.config.environment);
    cdk.Tags.of(this).add('Project', 'FineFinds');
    cdk.Tags.of(this).add('ManagedBy', 'CDK');
    cdk.Tags.of(this).add('Component', 'SonarQube');
  }
} 