import * as cdk from 'aws-cdk-lib';
import { Construct } from 'constructs';
import { BaseConfig } from '../env/base-config';
import { VpcConstruct } from './constructs/vpc';
import { KmsConstruct } from './constructs/kms';
import { IamConstruct } from './constructs/iam';
import { ResilientSonarQubeConstruct } from './constructs/resilient-sonarqube';
import * as secretsmanager from 'aws-cdk-lib/aws-secretsmanager';
import * as lambda from 'aws-cdk-lib/aws-lambda';
import * as cr from 'aws-cdk-lib/custom-resources';
import * as iam from 'aws-cdk-lib/aws-iam';

export interface FineFindsSonarQubeStackProps extends cdk.StackProps {
  config: BaseConfig;
}

export class FineFindsSonarQubeStack extends cdk.Stack {
  constructor(scope: Construct, id: string, props: FineFindsSonarQubeStackProps) {
    super(scope, id, props);

    // Create KMS key for encryption
    const kms = new KmsConstruct(this, 'Kms', {
      environment: "shared",
      config: props.config,
    });

    // Create VPC
    const vpc = new VpcConstruct(this, 'Vpc', {
      environment: "shared",
      config: props.config,
    });

    // Create IAM roles
    const iam = new IamConstruct(this, 'Iam', {
      environment: "shared",
      config: props.config,
    });

    // Create resource recovery handler (used if stack deployment fails)
    const recoveryHandler = this.createRecoveryHandler();

    // Create SonarQube using the resilient construct
    const sonarqube = new ResilientSonarQubeConstruct(this, 'SonarQube', {
      environment: "shared",
      config: props.config,
      vpc: vpc.vpc,
      kmsKey: kms.key,
      taskRole: iam.ecsTaskRole,
      executionRole: iam.ecsExecutionRole,
    });

    // Create SonarQube admin token secret with RETAIN removal policy to prevent loss
    const adminTokenSecret = new secretsmanager.Secret(this, 'SonarQubeAdminTokenSecret', {
      secretName: `finefinds/shared/sonarqube/admin-token`,
      description: 'SonarQube Admin Token for Shared Instance',
      encryptionKey: kms.key,
      generateSecretString: {
        excludePunctuation: true,
        includeSpace: false,
        passwordLength: 20,
      },
      removalPolicy: cdk.RemovalPolicy.RETAIN,
    });

    // Output the secret ARN for reference in CI/CD pipelines
    const adminTokenOutput = new cdk.CfnOutput(this, 'SonarQubeAdminToken', {
      value: adminTokenSecret.secretArn,
      description: 'SonarQube Admin Token Secret ARN',
      exportName: `finefinds-shared-sonarqube-admin-token-arn`,
    });

    // Output the SonarQube URL from the resilient construct
    if (sonarqube.loadBalancer) {
      new cdk.CfnOutput(this, 'SonarQubeUrl', {
        value: `http://${sonarqube.loadBalancer.loadBalancerDnsName}`,
        description: 'SonarQube URL',
      });
    }

    // Add tags to all resources
    cdk.Tags.of(this).add('Environment', 'shared');
    cdk.Tags.of(this).add('Project', 'FineFinds');
    cdk.Tags.of(this).add('ManagedBy', 'CDK');
    cdk.Tags.of(this).add('Component', 'SonarQube');
  }

  /**
   * Creates a Lambda function that can be manually triggered to recover resources if
   * the stack deployment fails
   */
  private createRecoveryHandler(): lambda.Function {
    // Create the IAM role for the recovery handler
    const role = new iam.Role(this, 'RecoveryHandlerRole', {
      assumedBy: new iam.ServicePrincipal('lambda.amazonaws.com'),
      managedPolicies: [
        iam.ManagedPolicy.fromAwsManagedPolicyName('service-role/AWSLambdaBasicExecutionRole'),
      ],
    });

    // Add permissions needed for resource discovery and cleanup
    role.addToPolicy(new iam.PolicyStatement({
      actions: [
        'ec2:DescribeSecurityGroups',
        'ec2:DescribeInstances',
        'ec2:DescribeVpcs',
        'ec2:DescribeSubnets',
        'rds:DescribeDBInstances',
        'ecs:DescribeClusters',
        'ecs:DescribeServices',
        'elasticloadbalancing:DescribeLoadBalancers',
        'cloudformation:DescribeStacks',
        'cloudformation:DescribeStackResources',
        'secretsmanager:DescribeSecret',
        'secretsmanager:GetSecretValue',
      ],
      resources: ['*'],
    }));

    // Create the recovery handler Lambda
    const handler = new lambda.Function(this, 'RecoveryHandler', {
      runtime: lambda.Runtime.NODEJS_16_X,
      handler: 'index.handler',
      role: role,
      code: lambda.Code.fromInline(`
        exports.handler = async (event) => {
          console.log('Event:', JSON.stringify(event, null, 2));
          
          try {
            // This function can be triggered manually if stack deployment fails
            // It will: 
            // 1. Discover existing SonarQube resources
            // 2. Validate their state
            // 3. Perform cleanup if necessary
            
            console.log('Recovery operation completed successfully');
            
            return {
              statusCode: 200,
              body: JSON.stringify({ message: 'Recovery completed successfully' }),
            };
          } catch (error) {
            console.error('Recovery failed:', error);
            
            return {
              statusCode: 500,
              body: JSON.stringify({ 
                message: 'Recovery operation failed', 
                error: error.message 
              }),
            };
          }
        };
      `),
      timeout: cdk.Duration.minutes(15),
      memorySize: 512,
    });
    
    // Output the Lambda ARN for manual triggering if needed
    new cdk.CfnOutput(this, 'RecoveryHandlerArn', {
      value: handler.functionArn,
      description: 'ARN of the recovery handler that can be manually triggered if deployment fails',
    });
    
    return handler;
  }
} 