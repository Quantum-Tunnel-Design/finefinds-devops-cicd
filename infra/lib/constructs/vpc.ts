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