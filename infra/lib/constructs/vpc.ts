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
      natGateways: props.environment === 'prod' ? props.config.vpc.natGateways : 0,
      ipAddresses: ec2.IpAddresses.cidr(props.config.vpc.cidr),
      subnetConfiguration: props.environment === 'prod' 
        ? [
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
          ] 
        : [
            // Simplified subnet configuration for non-prod
            {
              name: 'Public',
              subnetType: ec2.SubnetType.PUBLIC,
              cidrMask: 24,
            },
            {
              name: 'Private',
              subnetType: ec2.SubnetType.PRIVATE_ISOLATED,
              cidrMask: 24,
            },
          ],
      enableDnsHostnames: true,
      enableDnsSupport: true,
    });

    // Add VPC Flow Logs
    this.vpc.addFlowLog('FlowLog');

    // Add VPC endpoints for private subnets to access AWS services
    // These are necessary for private subnets to communicate with AWS services without NAT gateways
    
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
    
    // Gateway endpoints (S3 & DynamoDB) - these are free
    new ec2.GatewayVpcEndpoint(this, 'S3Endpoint', {
      vpc: this.vpc,
      service: ec2.GatewayVpcEndpointAwsService.S3,
    });
    
    new ec2.GatewayVpcEndpoint(this, 'DynamoDbEndpoint', {
      vpc: this.vpc,
      service: ec2.GatewayVpcEndpointAwsService.DYNAMODB,
    });
    
    // Interface endpoints (not free, but needed for services like ECR)
    // Get private subnets to deploy the endpoints in
    const privateSubnets = this.vpc.selectSubnets({
      subnetType: ec2.SubnetType.PRIVATE_ISOLATED,
    });
    
    // ECR endpoints - critical for pulling images (deploy these first)
    // ECR API endpoint
    new ec2.InterfaceVpcEndpoint(this, 'EcrEndpoint', {
      vpc: this.vpc,
      service: ec2.InterfaceVpcEndpointAwsService.ECR,
      subnets: { subnets: privateSubnets.subnets },
      privateDnsEnabled: true,
      securityGroups: [endpointSecurityGroup],
    });
    
    // ECR Docker API endpoint
    new ec2.InterfaceVpcEndpoint(this, 'EcrDockerEndpoint', {
      vpc: this.vpc,
      service: ec2.InterfaceVpcEndpointAwsService.ECR_DOCKER,
      subnets: { subnets: privateSubnets.subnets },
      privateDnsEnabled: true,
      securityGroups: [endpointSecurityGroup],
    });
    
    // Add additional required endpoints based on environment type to avoid quota issues
    if (props.environment === 'prod') {
      // Full set of endpoints for production
      
      // CloudWatch Logs endpoint - for container logging
      new ec2.InterfaceVpcEndpoint(this, 'LogsEndpoint', {
        vpc: this.vpc,
        service: ec2.InterfaceVpcEndpointAwsService.CLOUDWATCH_LOGS,
        subnets: { subnets: privateSubnets.subnets },
        privateDnsEnabled: true,
        securityGroups: [endpointSecurityGroup],
      });
      
      // Secrets Manager endpoint - for retrieving secrets
      new ec2.InterfaceVpcEndpoint(this, 'SecretsManagerEndpoint', {
        vpc: this.vpc,
        service: ec2.InterfaceVpcEndpointAwsService.SECRETS_MANAGER,
        subnets: { subnets: privateSubnets.subnets },
        privateDnsEnabled: true,
        securityGroups: [endpointSecurityGroup],
      });
      
      // SSM endpoint - for parameter store if needed
      new ec2.InterfaceVpcEndpoint(this, 'SsmEndpoint', {
        vpc: this.vpc,
        service: ec2.InterfaceVpcEndpointAwsService.SSM,
        subnets: { subnets: privateSubnets.subnets },
        privateDnsEnabled: true,
        securityGroups: [endpointSecurityGroup],
      });
    } else {
      // Minimum set for non-production environments - just add CloudWatch Logs
      new ec2.InterfaceVpcEndpoint(this, 'LogsEndpoint', {
        vpc: this.vpc,
        service: ec2.InterfaceVpcEndpointAwsService.CLOUDWATCH_LOGS,
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