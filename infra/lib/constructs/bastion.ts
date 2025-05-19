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
        const https = require('https');
        const url = require('url');

        // Initialize AWS services with retry configuration
        const config = new AWS.Config({
          maxRetries: 3,
          retryDelayOptions: { base: 300 }
        });
        const ec2 = new AWS.EC2(config);
        const secretsManager = new AWS.SecretsManager(config);

        const cfnResponse = {
          SUCCESS: 'SUCCESS',
          FAILED: 'FAILED',
          send: function(event, context, responseStatus, responseData, physicalResourceId) {
            console.log('Sending response to CloudFormation:', {
              status: responseStatus,
              data: responseData,
              physicalResourceId: physicalResourceId
            });

            const responseBody = JSON.stringify({
              Status: responseStatus,
              Reason: responseStatus === 'FAILED' ? responseData.error : 'See the details in CloudWatch Log Stream: ' + context.logStreamName,
              PhysicalResourceId: physicalResourceId || context.logStreamName,
              StackId: event.StackId,
              RequestId: event.RequestId,
              LogicalResourceId: event.LogicalResourceId,
              Data: responseData
            });

            const parsedUrl = url.parse(event.ResponseURL);
            const options = {
              hostname: parsedUrl.hostname,
              port: 443,
              path: parsedUrl.path,
              method: 'PUT',
              headers: {
                'content-type': '',
                'content-length': responseBody.length
              }
            };

            return new Promise((resolve, reject) => {
              const request = https.request(options, (response) => {
                console.log('CloudFormation response status:', response.statusCode);
                console.log('CloudFormation response message:', response.statusMessage);
                resolve();
              });

              request.on('error', (error) => {
                console.error('Failed to send response to CloudFormation:', error);
                reject(error);
              });

              request.write(responseBody);
              request.end();
            });
          }
        };

        exports.handler = async (event, context) => {
          console.log('Received event:', JSON.stringify(event, null, 2));
          
          // Set a timeout to ensure we respond to CloudFormation
          const timeout = setTimeout(() => {
            console.error('Function timed out');
            cfnResponse.send(event, context, cfnResponse.FAILED, {
              error: 'Function timed out after 5 minutes'
            });
          }, 4 * 60 * 1000); // 4 minutes (leaving 1 minute buffer)
          
          try {
            if (event.RequestType === 'Create' || event.RequestType === 'Update') {
              console.log('Creating/Updating key pair:', event.ResourceProperties.KeyName);
              
              // Create key pair with retry logic
              let keyPair;
              let retries = 0;
              const maxRetries = 3;
              
              while (retries < maxRetries) {
                try {
                  keyPair = await ec2.createKeyPair({
                    KeyName: event.ResourceProperties.KeyName,
                    TagSpecifications: [{
                      ResourceType: 'key-pair',
                      Tags: [
                        { Key: 'Environment', Value: event.ResourceProperties.Environment },
                        { Key: 'Project', Value: 'FineFinds' }
                      ]
                    }]
                  }).promise();
                  break;
                } catch (error) {
                  retries++;
                  if (retries === maxRetries) throw error;
                  console.log(\`Retry \${retries} of \${maxRetries} for key pair creation\`);
                  await new Promise(resolve => setTimeout(resolve, 1000 * retries));
                }
              }

              console.log('Key pair created successfully');

              // Store private key in Secrets Manager with retry logic
              retries = 0;
              while (retries < maxRetries) {
                try {
                  await secretsManager.updateSecret({
                    SecretId: event.ResourceProperties.SecretArn,
                    SecretString: JSON.stringify({
                      keyPairName: keyPair.KeyName,
                      privateKey: keyPair.KeyMaterial
                    })
                  }).promise();
                  break;
                } catch (error) {
                  retries++;
                  if (retries === maxRetries) throw error;
                  console.log(\`Retry \${retries} of \${maxRetries} for secret update\`);
                  await new Promise(resolve => setTimeout(resolve, 1000 * retries));
                }
              }

              console.log('Private key stored in Secrets Manager');

              clearTimeout(timeout);
              await cfnResponse.send(event, context, cfnResponse.SUCCESS, {
                KeyName: keyPair.KeyName
              }, keyPair.KeyName);
            } else if (event.RequestType === 'Delete') {
              console.log('Deleting key pair:', event.PhysicalResourceId);
              
              // Delete key pair with retry logic
              let retries = 0;
              const maxRetries = 3;
              
              while (retries < maxRetries) {
                try {
                  await ec2.deleteKeyPair({
                    KeyName: event.PhysicalResourceId
                  }).promise();
                  break;
                } catch (error) {
                  retries++;
                  if (retries === maxRetries) throw error;
                  console.log(\`Retry \${retries} of \${maxRetries} for key pair deletion\`);
                  await new Promise(resolve => setTimeout(resolve, 1000 * retries));
                }
              }
              
              console.log('Key pair deleted successfully');
              
              clearTimeout(timeout);
              await cfnResponse.send(event, context, cfnResponse.SUCCESS, {}, event.PhysicalResourceId);
            }
          } catch (error) {
            console.error('Error occurred:', error);
            clearTimeout(timeout);
            await cfnResponse.send(event, context, cfnResponse.FAILED, { 
              error: error.message,
              stack: error.stack
            });
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