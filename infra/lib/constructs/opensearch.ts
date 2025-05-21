import * as cdk from 'aws-cdk-lib';
import * as opensearch from 'aws-cdk-lib/aws-opensearchservice';
import * as ec2 from 'aws-cdk-lib/aws-ec2';
import * as iam from 'aws-cdk-lib/aws-iam';
import * as logs from 'aws-cdk-lib/aws-logs';
import { Construct } from 'constructs';
import { BaseConfig } from '../../env/base-config';

export interface OpenSearchConstructProps {
  environment: string;
  vpc: ec2.Vpc;
  kmsKey: cdk.aws_kms.Key;
  config: BaseConfig;
}

export class OpenSearchConstruct extends Construct {
  public readonly domain?: opensearch.Domain;

  constructor(scope: Construct, id: string, props: OpenSearchConstructProps) {
    super(scope, id);

    // Only create OpenSearch in production environment
    if (props.environment === 'prod') {
      // Create security group for OpenSearch
      const securityGroup = new ec2.SecurityGroup(this, 'OpenSearchSecurityGroup', {
        vpc: props.vpc,
        description: 'Security group for OpenSearch domain',
        allowAllOutbound: true,
      });

      // Allow inbound OpenSearch access from ECS tasks
      securityGroup.addIngressRule(
        ec2.Peer.ipv4(props.vpc.vpcCidrBlock),
        ec2.Port.tcp(443),
        'Allow OpenSearch access from within VPC'
      );

      // Create OpenSearch domain
      this.domain = new opensearch.Domain(this, 'Domain', {
        domainName: `finefinds-${props.environment}`,
        version: opensearch.EngineVersion.OPENSEARCH_2_5,
        vpc: props.vpc,
        vpcSubnets: [
          {
            subnetType: ec2.SubnetType.PRIVATE_WITH_EGRESS,
          },
        ],
        securityGroups: [securityGroup],
        capacity: {
          masterNodes: 3,
          masterNodeInstanceType: 'r6g.large.search',
          dataNodes: 3,
          dataNodeInstanceType: 'r6g.large.search',
        },
        ebs: {
          volumeSize: 100,
          volumeType: ec2.EbsDeviceVolumeType.GP3,
          iops: 3000,
        },
        zoneAwareness: {
          enabled: true,
          availabilityZoneCount: 3,
        },
        encryptionAtRest: {
          enabled: true,
          kmsKey: props.kmsKey,
        },
        nodeToNodeEncryption: true,
        enforceHttps: true,
        tlsSecurityPolicy: opensearch.TLSSecurityPolicy.TLS_1_2,
        logging: {
          slowSearchLogEnabled: true,
          appLogEnabled: true,
          slowIndexLogEnabled: true,
          auditLogEnabled: true,
          slowSearchLogGroup: new logs.LogGroup(this, 'SlowSearchLogs', {
            logGroupName: `finefinds-${props.environment}-opensearch-slow-search-logs`,
            retention: logs.RetentionDays.ONE_MONTH,
            encryptionKey: props.kmsKey,
            removalPolicy: cdk.RemovalPolicy.RETAIN,
          }),
          appLogGroup: new logs.LogGroup(this, 'AppLogs', {
            logGroupName: `finefinds-${props.environment}-opensearch-app-logs`,
            retention: logs.RetentionDays.ONE_MONTH,
            encryptionKey: props.kmsKey,
            removalPolicy: cdk.RemovalPolicy.RETAIN,
          }),
          slowIndexLogGroup: new logs.LogGroup(this, 'SlowIndexLogs', {
            logGroupName: `finefinds-${props.environment}-opensearch-slow-index-logs`,
            retention: logs.RetentionDays.ONE_MONTH,
            encryptionKey: props.kmsKey,
            removalPolicy: cdk.RemovalPolicy.RETAIN,
          }),
          auditLogGroup: new logs.LogGroup(this, 'AuditLogs', {
            logGroupName: `finefinds-${props.environment}-opensearch-audit-logs`,
            retention: logs.RetentionDays.ONE_MONTH,
            encryptionKey: props.kmsKey,
            removalPolicy: cdk.RemovalPolicy.RETAIN,
          }),
        },
        accessPolicies: [
          new iam.PolicyStatement({
            actions: ['es:*'],
            effect: iam.Effect.ALLOW,
            principals: [new iam.AccountPrincipal(cdk.Stack.of(this).account)],
            resources: ['*'],
          }),
        ],
        removalPolicy: cdk.RemovalPolicy.RETAIN,
      });

      // Output OpenSearch domain ARN
      new cdk.CfnOutput(this, 'DomainArn', {
        value: this.domain.domainArn,
        description: 'OpenSearch Domain ARN',
        exportName: `finefinds-${props.environment}-opensearch-domain-arn`,
      });

      // Output OpenSearch domain endpoint
      new cdk.CfnOutput(this, 'DomainEndpoint', {
        value: this.domain.domainEndpoint,
        description: 'OpenSearch Domain Endpoint',
        exportName: `finefinds-${props.environment}-opensearch-domain-endpoint`,
      });
    } else {
      // For non-prod environments, we'll skip OpenSearch
      console.log('OpenSearch is disabled for non-production environments to reduce costs and complexity.');
    }
  }
} 