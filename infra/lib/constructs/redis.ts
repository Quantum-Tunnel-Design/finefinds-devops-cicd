import * as cdk from 'aws-cdk-lib';
import * as ec2 from 'aws-cdk-lib/aws-ec2';
import * as elasticache from 'aws-cdk-lib/aws-elasticache';
import * as sns from 'aws-cdk-lib/aws-sns';
import { Construct } from 'constructs';
import { BaseConfig } from '../../env/base-config';
import { RedisMonitoring } from './redis-monitoring';

export interface RedisConstructProps {
  environment: string;
  config: BaseConfig;
  vpc: ec2.IVpc;
  alarmTopic: sns.Topic;
}

export class RedisConstruct extends Construct {
  public readonly cluster: elasticache.CfnCacheCluster;
  public readonly securityGroup: ec2.SecurityGroup;
  public readonly subnetGroup: elasticache.CfnSubnetGroup;
  public readonly monitoring: RedisMonitoring;

  constructor(scope: Construct, id: string, props: RedisConstructProps) {
    super(scope, id);

    // Create security group for Redis
    this.securityGroup = new ec2.SecurityGroup(this, 'RedisSecurityGroup', {
      vpc: props.vpc,
      description: 'Security group for Redis ElastiCache cluster',
      allowAllOutbound: true,
    });

    // Allow inbound Redis traffic from ECS tasks
    this.securityGroup.addIngressRule(
      ec2.Peer.ipv4(props.vpc.vpcCidrBlock),
      ec2.Port.tcp(6379),
      'Allow Redis access from within VPC'
    );

    // Create subnet group for Redis
    this.subnetGroup = new elasticache.CfnSubnetGroup(this, 'RedisSubnetGroup', {
      description: 'Subnet group for Redis ElastiCache cluster',
      subnetIds: props.environment === 'prod'
        ? props.vpc.selectSubnets({ subnetType: ec2.SubnetType.PRIVATE_WITH_EGRESS }).subnetIds
        : props.vpc.selectSubnets({ subnetType: ec2.SubnetType.PRIVATE_WITH_EGRESS }).subnetIds,
    });

    // Create Redis cluster
    this.cluster = new elasticache.CfnCacheCluster(this, 'RedisCluster', {
      engine: 'redis',
      cacheNodeType: props.config.redis.nodeType,
      numCacheNodes: props.config.redis.numNodes,
      port: 6379,
      vpcSecurityGroupIds: [this.securityGroup.securityGroupId],
      cacheSubnetGroupName: this.subnetGroup.ref,
      engineVersion: props.config.redis.engineVersion,
      autoMinorVersionUpgrade: true,
      snapshotRetentionLimit: props.config.redis.snapshotRetentionLimit,
      snapshotWindow: props.config.redis.snapshotWindow,
      preferredMaintenanceWindow: props.config.redis.maintenanceWindow,
      tags: [
        {
          key: 'Environment',
          value: props.environment,
        },
        {
          key: 'Project',
          value: 'FineFinds',
        },
      ],
    });

    // Create monitoring
    this.monitoring = new RedisMonitoring(this, 'RedisMonitoring', {
      environment: props.environment,
      config: props.config,
      clusterId: this.cluster.ref,
      alarmTopic: props.alarmTopic,
    });

    // Output Redis endpoint
    new cdk.CfnOutput(this, 'RedisEndpoint', {
      value: this.cluster.attrRedisEndpointAddress,
      description: 'Redis ElastiCache endpoint',
      exportName: `finefinds-${props.environment}-redis-cache-endpoint`,
    });
  }
} 