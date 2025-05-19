import * as cdk from 'aws-cdk-lib';
import * as ec2 from 'aws-cdk-lib/aws-ec2';
import * as iam from 'aws-cdk-lib/aws-iam';
import * as secretsmanager from 'aws-cdk-lib/aws-secretsmanager';
import * as lambda from 'aws-cdk-lib/aws-lambda';
import { CustomResource } from 'aws-cdk-lib';
import { Construct } from 'constructs';
import { BaseConfig } from '../../env/base-config';

interface BastionConstructProps {
  environment: string;
  config: BaseConfig;
  vpc: ec2.IVpc;
}

export class BastionConstruct extends Construct {
  public readonly instance: ec2.Instance;
  public readonly securityGroup: ec2.SecurityGroup;
  public readonly keyPairSecret: secretsmanager.ISecret;

  constructor(scope: Construct, id: string, props: BastionConstructProps) {
    super(scope, id);

    // Only create bastion host for non-production environments
    if (props.environment === 'prod') {
      return;
    }

    // Create or import key pair
    const keyPairName = props.config.bastion?.keyName || `finefinds-${props.environment}-bastion`;
    
    // Create a secret to store the private key
    this.keyPairSecret = new secretsmanager.Secret(this, 'BastionKeyPairSecret', {
      secretName: `finefinds-${props.environment}-bastion-key`,
      description: 'Private key for bastion host access',
    });

    // Create Lambda function to handle key pair creation and storage
    const keyPairHandler = new lambda.Function(this, 'KeyPairHandler', {
      runtime: lambda.Runtime.NODEJS_18_X,
      handler: 'index.handler',
      code: lambda.Code.fromInline(`
        const AWS = require('aws-sdk');
        const ec2 = new AWS.EC2();
        const secretsManager = new AWS.SecretsManager();
        const response = require('cfn-response');

        exports.handler = async (event, context) => {
          console.log('Event:', JSON.stringify(event, null, 2));
          
          try {
            if (event.RequestType === 'Create' || event.RequestType === 'Update') {
              // Create key pair
              const keyPair = await ec2.createKeyPair({
                KeyName: event.ResourceProperties.KeyName,
                TagSpecifications: [{
                  ResourceType: 'key-pair',
                  Tags: [
                    { Key: 'Environment', Value: event.ResourceProperties.Environment },
                    { Key: 'Project', Value: 'FineFinds' }
                  ]
                }]
              }).promise();

              // Store private key in Secrets Manager
              await secretsManager.updateSecret({
                SecretId: event.ResourceProperties.SecretArn,
                SecretString: JSON.stringify({
                  keyPairName: keyPair.KeyName,
                  privateKey: keyPair.KeyMaterial
                })
              }).promise();

              await response.send(event, context, response.SUCCESS, {
                KeyName: keyPair.KeyName
              }, keyPair.KeyName);
            } else if (event.RequestType === 'Delete') {
              // Delete key pair
              await ec2.deleteKeyPair({
                KeyName: event.PhysicalResourceId
              }).promise();
              
              await response.send(event, context, response.SUCCESS, {}, event.PhysicalResourceId);
            }
          } catch (error) {
            console.error('Error:', error);
            await response.send(event, context, response.FAILED, { error: error.message });
          }
        };
      `),
      timeout: cdk.Duration.minutes(5),
      environment: {
        NODE_OPTIONS: '--enable-source-maps',
      },
    });

    // Grant permissions to the Lambda function
    keyPairHandler.addToRolePolicy(new iam.PolicyStatement({
      effect: iam.Effect.ALLOW,
      actions: [
        'ec2:CreateKeyPair',
        'ec2:DeleteKeyPair',
        'ec2:CreateTags',
        'ec2:DescribeKeyPairs'
      ],
      resources: ['*']
    }));

    keyPairHandler.addToRolePolicy(new iam.PolicyStatement({
      effect: iam.Effect.ALLOW,
      actions: [
        'secretsmanager:UpdateSecret',
        'secretsmanager:GetSecretValue'
      ],
      resources: [this.keyPairSecret.secretArn]
    }));

    // Create custom resource to invoke the Lambda function
    const keyPairResource = new CustomResource(this, 'KeyPairResource', {
      serviceToken: keyPairHandler.functionArn,
      properties: {
        KeyName: keyPairName,
        Environment: props.environment,
        SecretArn: this.keyPairSecret.secretArn,
      },
    });

    // Create security group for the bastion host
    this.securityGroup = new ec2.SecurityGroup(this, 'BastionSecurityGroup', {
      vpc: props.vpc,
      description: 'Security group for bastion host',
      allowAllOutbound: true,
    });

    // Allow inbound SSH access from anywhere (you might want to restrict this to specific IPs)
    this.securityGroup.addIngressRule(
      ec2.Peer.anyIpv4(),
      ec2.Port.tcp(22),
      'Allow SSH access'
    );

    // Create IAM role for the bastion host
    const role = new iam.Role(this, 'BastionRole', {
      assumedBy: new iam.ServicePrincipal('ec2.amazonaws.com'),
      description: 'Role for bastion host',
    });

    // Add necessary permissions for SSM
    role.addManagedPolicy(
      iam.ManagedPolicy.fromAwsManagedPolicyName('AmazonSSMManagedInstanceCore')
    );

    // Create the bastion host instance
    this.instance = new ec2.Instance(this, 'BastionHost', {
      vpc: props.vpc,
      vpcSubnets: {
        subnetType: ec2.SubnetType.PUBLIC,
      },
      instanceType: ec2.InstanceType.of(
        ec2.InstanceClass.T3,
        ec2.InstanceSize.MICRO
      ),
      machineImage: ec2.MachineImage.latestAmazonLinux2023(),
      securityGroup: this.securityGroup,
      role: role,
      keyName: keyPairName,
      userData: ec2.UserData.forLinux(),
    });

    // Add user data script to install PostgreSQL client
    this.instance.userData.addCommands(
      'yum update -y',
      'yum install -y postgresql15'
    );

    // Output the bastion host's public IP
    new cdk.CfnOutput(this, 'BastionPublicIp', {
      value: this.instance.instancePublicIp,
      description: 'Public IP of the bastion host',
      exportName: `finefinds-${props.environment}-bastion-public-ip`,
    });

    // Output the key pair secret ARN
    new cdk.CfnOutput(this, 'BastionKeyPairSecretArn', {
      value: this.keyPairSecret.secretArn,
      description: 'ARN of the secret containing the bastion host private key',
      exportName: `finefinds-${props.environment}-bastion-key-secret-arn`,
    });

    // Add tags
    cdk.Tags.of(this.instance).add('Name', `finefinds-${props.environment}-bastion`);
    cdk.Tags.of(this.instance).add('Environment', props.environment);
    cdk.Tags.of(this.instance).add('Project', 'FineFinds');
  }
} 