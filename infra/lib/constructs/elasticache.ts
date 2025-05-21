import * as cdk from 'aws-cdk-lib';
import * as ec2 from 'aws-cdk-lib/aws-ec2';
import * as elasticache from 'aws-cdk-lib/aws-elasticache';
import * as logs from 'aws-cdk-lib/aws-logs';
import { Construct } from 'constructs';
import { BaseConfig } from '../../env/base-config';

export interface ElastiCacheConstructProps {
  environment: string;
  config: BaseConfig;
  vpc: ec2.Vpc;
  kmsKey: cdk.aws_kms.Key;
}

export class ElastiCacheConstruct extends Construct {
  public readonly replicationGroup: elasticache.CfnReplicationGroup;

  constructor(scope: Construct, id: string, props: ElastiCacheConstructProps) {
    super(scope, id);

    // Create security group for Redis
    const securityGroup = new ec2.SecurityGroup(this, 'RedisSecurityGroup', {
      vpc: props.vpc,
      description: 'Security group for Redis cluster',
      allowAllOutbound: true,
    });

    // Allow inbound Redis access from ECS tasks
    securityGroup.addIngressRule(
      ec2.Peer.ipv4(props.vpc.vpcCidrBlock),
      ec2.Port.tcp(6379),
      'Allow Redis access from within VPC'
    );

    // Create subnet group
    const subnetGroup = new elasticache.CfnSubnetGroup(this, 'RedisSubnetGroup', {
      description: 'Subnet group for Redis cluster',
      subnetIds: props.vpc.privateSubnets.map(subnet => subnet.subnetId),
    });

    // Create parameter group
    const parameterGroup = new elasticache.CfnParameterGroup(this, 'RedisParameterGroup', {
      description: 'Parameter group for Redis cluster',
      cacheParameterGroupFamily: 'redis6.x',
      properties: {
        'maxmemory-policy': 'allkeys-lru',
        'notify-keyspace-events': 'Ex',
        'timeout': '0',
        'tcp-keepalive': '300',
      },
    });

    // Create replication group
    this.replicationGroup = new elasticache.CfnReplicationGroup(this, 'RedisReplicationGroup', {
      replicationGroupDescription: `finefinds-${props.environment}-redis-cluster`,
      engine: 'redis',
      engineVersion: '6.2',
      cacheNodeType: props.environment === 'prod' ? 'cache.r6g.large' : 'cache.t3.micro',
      numCacheClusters: props.environment === 'prod' ? 2 : 1,
      automaticFailoverEnabled: props.environment === 'prod',
      multiAzEnabled: props.environment === 'prod',
      atRestEncryptionEnabled: true,
      transitEncryptionEnabled: true,
      kmsKeyId: props.kmsKey.keyId,
      cacheSubnetGroupName: subnetGroup.ref,
      cacheParameterGroupName: parameterGroup.ref,
      securityGroupIds: [securityGroup.securityGroupId],
      port: 6379,
      logDeliveryConfigurations: props.environment === 'prod' ? [
        {
          destinationType: 'cloudwatch-logs',
          logFormat: 'json',
          logType: 'slow-log',
          destinationDetails: {
            cloudWatchLogsDetails: {
              logGroup: new logs.LogGroup(this, 'RedisSlowLogs', {
                logGroupName: `finefinds-${props.environment}-redis-slow-logs`,
                retention: logs.RetentionDays.ONE_MONTH,
                removalPolicy: cdk.RemovalPolicy.RETAIN,
              }).logGroupName,
            },
          },
        },
        {
          destinationType: 'cloudwatch-logs',
          logFormat: 'json',
          logType: 'engine-log',
          destinationDetails: {
            cloudWatchLogsDetails: {
              logGroup: new logs.LogGroup(this, 'RedisEngineLogs', {
                logGroupName: `finefinds-${props.environment}-redis-engine-logs`,
                retention: logs.RetentionDays.ONE_MONTH,
                removalPolicy: cdk.RemovalPolicy.RETAIN,
              }).logGroupName,
            },
          },
        },
      ] : undefined,
      tags: [
        {
          key: 'Environment',
          value: props.environment,
        },
        {
          key: 'Project',
          value: 'finefinds',
        },
      ],
    });

    // Output Redis endpoint
    new cdk.CfnOutput(this, 'RedisEndpoint', {
      value: this.replicationGroup.attrPrimaryEndPointAddress,
      description: 'Redis Primary Endpoint',
      exportName: `finefinds-${props.environment}-replication-redis-endpoint`,
    });

    // Output Redis port
    new cdk.CfnOutput(this, 'RedisPort', {
      value: this.replicationGroup.attrPrimaryEndPointPort,
      description: 'Redis Port',
      exportName: `finefinds-${props.environment}-redis-port`,
    });
  }
} 