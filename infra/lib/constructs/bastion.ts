import * as cdk from 'aws-cdk-lib';
import * as ec2 from 'aws-cdk-lib/aws-ec2';
import * as iam from 'aws-cdk-lib/aws-iam';
import * as logs from 'aws-cdk-lib/aws-logs';
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
  public readonly keyPair: ec2.CfnKeyPair;

  constructor(scope: Construct, id: string, props: BastionConstructProps) {
    super(scope, id);

    // Only create bastion host for non-production environments
    if (props.environment === 'prod') {
      return;
    }

    // Create or import key pair
    const keyPairName = props.config.bastion?.keyName || `finefinds-${props.environment}-bastion`;
    this.keyPair = new ec2.CfnKeyPair(this, 'BastionKeyPair', {
      keyName: keyPairName,
      tags: [
        { key: 'Environment', value: props.environment },
        { key: 'Project', value: 'FineFinds' }
      ]
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

    // Output the key pair name
    new cdk.CfnOutput(this, 'BastionKeyPairName', {
      value: keyPairName,
      description: 'Name of the key pair for bastion host access',
      exportName: `finefinds-${props.environment}-bastion-key-pair`,
    });

    // Add tags
    cdk.Tags.of(this.instance).add('Name', `finefinds-${props.environment}-bastion`);
    cdk.Tags.of(this.instance).add('Environment', props.environment);
    cdk.Tags.of(this.instance).add('Project', 'FineFinds');
  }
} 