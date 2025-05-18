import * as cdk from 'aws-cdk-lib';
import * as ec2 from 'aws-cdk-lib/aws-ec2';
import * as iam from 'aws-cdk-lib/aws-iam';
import * as logs from 'aws-cdk-lib/aws-logs';
import { Construct } from 'constructs';
import { BaseConfig } from '../../env/base-config';

export interface BastionConstructProps {
  environment: string;
  config: BaseConfig;
  vpc: ec2.Vpc;
}

export class BastionConstruct extends Construct {
  public readonly instance: ec2.Instance;
  public readonly securityGroup: ec2.SecurityGroup;

  constructor(scope: Construct, id: string, props: BastionConstructProps) {
    super(scope, id);

    // Create security group for bastion host
    this.securityGroup = new ec2.SecurityGroup(this, 'BastionSecurityGroup', {
      vpc: props.vpc,
      description: 'Security group for bastion host',
      allowAllOutbound: true,
    });

    // Allow inbound SSH access from anywhere (you might want to restrict this to your IP)
    this.securityGroup.addIngressRule(
      ec2.Peer.anyIpv4(),
      ec2.Port.tcp(22),
      'Allow SSH access'
    );

    // Create IAM role for bastion host with necessary permissions
    const role = new iam.Role(this, 'BastionRole', {
      assumedBy: new iam.ServicePrincipal('ec2.amazonaws.com'),
      managedPolicies: [
        iam.ManagedPolicy.fromAwsManagedPolicyName('AmazonSSMManagedInstanceCore'),
        iam.ManagedPolicy.fromAwsManagedPolicyName('CloudWatchAgentServerPolicy'),
      ],
    });

    // Add custom policy for RDS access
    role.addToPolicy(
      new iam.PolicyStatement({
        effect: iam.Effect.ALLOW,
        actions: [
          'rds-db:connect',
          'rds:DescribeDBInstances',
          'rds:DescribeDBClusters',
        ],
        resources: ['*'],
      })
    );

    // Create user data script for bastion host
    const userData = ec2.UserData.forLinux();
    userData.addCommands(
      // Update system
      'yum update -y',
      // Install required packages
      'yum install -y postgresql15',
      // Configure CloudWatch agent
      'yum install -y amazon-cloudwatch-agent',
      // Create CloudWatch agent config
      `cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json << 'EOF'
{
  "agent": {
    "metrics_collection_interval": 60,
    "run_as_user": "root"
  },
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/var/log/secure",
            "log_group_name": "/finefinds/${props.environment}/bastion/secure",
            "log_stream_name": "{instance_id}",
            "timezone": "UTC"
          },
          {
            "file_path": "/var/log/messages",
            "log_group_name": "/finefinds/${props.environment}/bastion/messages",
            "log_stream_name": "{instance_id}",
            "timezone": "UTC"
          }
        ]
      }
    }
  }
}
EOF`,
      // Start CloudWatch agent
      '/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -s -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json',
      // Enable CloudWatch agent service
      'systemctl enable amazon-cloudwatch-agent',
      'systemctl start amazon-cloudwatch-agent'
    );

    // Create bastion host
    this.instance = new ec2.Instance(this, 'BastionHost', {
      vpc: props.vpc,
      vpcSubnets: {
        subnetType: ec2.SubnetType.PUBLIC,
      },
      instanceType: ec2.InstanceType.of(
        ec2.InstanceClass.T3,
        ec2.InstanceSize.MICRO
      ),
      machineImage: ec2.MachineImage.latestAmazonLinux2023({
        userData: userData,
      }),
      securityGroup: this.securityGroup,
      role: role,
      keyName: props.config.bastion?.keyName,
      blockDevices: [
        {
          deviceName: '/dev/xvda',
          volume: ec2.BlockDeviceVolume.ebs(8, {
            volumeType: ec2.EbsDeviceVolumeType.GP3,
            encrypted: true,
          }),
        },
      ],
      requireImdsv2: true, // Require IMDSv2 for better security
    });

    // Create CloudWatch log group for bastion host
    new logs.LogGroup(this, 'BastionLogGroup', {
      logGroupName: `/finefinds/${props.environment}/bastion`,
      retention: logs.RetentionDays.ONE_MONTH,
      removalPolicy: cdk.RemovalPolicy.DESTROY,
    });

    // Output bastion host public IP
    new cdk.CfnOutput(this, 'BastionPublicIp', {
      value: this.instance.instancePublicIp,
      description: 'Bastion host public IP',
      exportName: `finefinds-${props.environment}-bastion-public-ip`,
    });

    // Output bastion host instance ID
    new cdk.CfnOutput(this, 'BastionInstanceId', {
      value: this.instance.instanceId,
      description: 'Bastion host instance ID',
      exportName: `finefinds-${props.environment}-bastion-instance-id`,
    });
  }
} 