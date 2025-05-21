import * as cdk from 'aws-cdk-lib';
import * as ec2 from 'aws-cdk-lib/aws-ec2';
import { Construct } from 'constructs';
import { BaseConfig } from '../../env/base-config';

export interface VpcConstructProps {
  environment: string;
  config: BaseConfig;
}

export class VpcConstruct extends Construct {
  public readonly vpc: ec2.Vpc;

  constructor(scope: Construct, id: string, props: VpcConstructProps) {
    super(scope, id);

    // Create VPC with public and private subnets
    this.vpc = new ec2.Vpc(this, 'Vpc', {
      maxAzs: props.environment === 'prod' ? props.config.vpc.maxAzs : 2,
      natGateways: 1, // Always have at least one NAT Gateway
      ipAddresses: ec2.IpAddresses.cidr(props.config.vpc.cidr),
      subnetConfiguration: [
        {
          name: 'Public',
          subnetType: ec2.SubnetType.PUBLIC,
          cidrMask: 24,
        },
        {
          name: 'Private',
          subnetType: ec2.SubnetType.PRIVATE_WITH_EGRESS,
          cidrMask: 24,
        },
        {
          name: 'Isolated',
          subnetType: ec2.SubnetType.PRIVATE_ISOLATED,
          cidrMask: 24,
        },
      ],
      enableDnsHostnames: true,
      enableDnsSupport: true,
    });

    // Add VPC Flow Logs
    this.vpc.addFlowLog('FlowLog');

    // Create security group for VPC endpoints
    const endpointSecurityGroup = new ec2.SecurityGroup(this, 'EndpointSecurityGroup', {
      vpc: this.vpc,
      description: 'Security group for VPC Endpoints',
      allowAllOutbound: true,
    });
    
    // Allow traffic from within the VPC to the endpoints
    endpointSecurityGroup.addIngressRule(
      ec2.Peer.ipv4(this.vpc.vpcCidrBlock),
      ec2.Port.tcp(443),
      'Allow HTTPS from within VPC'
    );
    
    // Gateway endpoints (S3 & DynamoDB) - these are free and don't count towards the quota
    new ec2.GatewayVpcEndpoint(this, 'S3Endpoint', {
      vpc: this.vpc,
      service: ec2.GatewayVpcEndpointAwsService.S3,
    });
    
    new ec2.GatewayVpcEndpoint(this, 'DynamoDbEndpoint', {
      vpc: this.vpc,
      service: ec2.GatewayVpcEndpointAwsService.DYNAMODB,
    });
    
    // Get private subnets to deploy the endpoints in
    const privateSubnets = this.vpc.selectSubnets({
      subnetType: ec2.SubnetType.PRIVATE_WITH_EGRESS,
    });

    // Essential interface endpoints only
    const essentialEndpoints = [
      {
        id: 'EcrEndpoint',
        service: ec2.InterfaceVpcEndpointAwsService.ECR,
        required: true,
      },
      {
        id: 'EcrDockerEndpoint',
        service: ec2.InterfaceVpcEndpointAwsService.ECR_DOCKER,
        required: true,
      },
      {
        id: 'LogsEndpoint',
        service: ec2.InterfaceVpcEndpointAwsService.CLOUDWATCH_LOGS,
        required: true,
      },
      {
        id: 'SecretsManagerEndpoint',
        service: ec2.InterfaceVpcEndpointAwsService.SECRETS_MANAGER,
        required: true,
      },
    ];

    // Add only essential endpoints
    essentialEndpoints.forEach(endpoint => {
      new ec2.InterfaceVpcEndpoint(this, endpoint.id, {
        vpc: this.vpc,
        service: endpoint.service,
        subnets: { subnets: privateSubnets.subnets },
        privateDnsEnabled: true,
        securityGroups: [endpointSecurityGroup],
      });
    });

    // Add RDS endpoint only if in production
    if (props.environment === 'prod') {
      new ec2.InterfaceVpcEndpoint(this, 'RdsEndpoint', {
        vpc: this.vpc,
        service: ec2.InterfaceVpcEndpointAwsService.RDS,
        subnets: { subnets: privateSubnets.subnets },
        privateDnsEnabled: true,
        securityGroups: [endpointSecurityGroup],
      });
    }

    // Add tags
    cdk.Tags.of(this.vpc).add('Environment', props.environment);
    cdk.Tags.of(this.vpc).add('Name', `finefinds-${props.environment}-vpc`);

    // Output VPC ID
    new cdk.CfnOutput(this, 'VpcId', {
      value: this.vpc.vpcId,
      description: 'VPC ID',
      exportName: `finefinds-${props.environment}-vpc-id`,
    });
  }
} 