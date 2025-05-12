import * as cdk from 'aws-cdk-lib';
import * as ec2 from 'aws-cdk-lib/aws-ec2';
import * as opensearch from 'aws-cdk-lib/aws-opensearchservice';
import * as logs from 'aws-cdk-lib/aws-logs';
import { Construct } from 'constructs';
import { BaseConfig } from '../../env/base-config';

export interface OpenSearchConstructProps {
  environment: string;
  config: BaseConfig;
  vpc: ec2.Vpc;
  kmsKey: cdk.aws_kms.Key;
}

export class OpenSearchConstruct extends Construct {
  public readonly domain: opensearch.Domain;

  constructor(scope: Construct, id: string, props: OpenSearchConstructProps) {
    super(scope, id);

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
        masterNodes: props.environment === 'prod' ? 3 : 1,
        masterNodeInstanceType: props.environment === 'prod' ? 'r6g.large.search' : 't3.small.search',
        dataNodes: props.environment === 'prod' ? 3 : 1,
        dataNodeInstanceType: props.environment === 'prod' ? 'r6g.large.search' : 't3.small.search',
      },
      ebs: {
        volumeSize: props.environment === 'prod' ? 100 : 20,
        volumeType: ec2.EbsDeviceVolumeType.GP3,
        iops: props.environment === 'prod' ? 3000 : 300,
      },
      zoneAwareness: {
        enabled: props.environment === 'prod',
        availabilityZoneCount: props.environment === 'prod' ? 3 : 1,
      },
      encryptionAtRest: {
        enabled: true,
        kmsKey: props.kmsKey,
      },
      nodeToNodeEncryption: true,
      enforceHttps: true,
      tlsSecurityPolicy: opensearch.TLSSecurityPolicy.TLS_1_2,
      fineGrainedAccessControl: {
        masterUserName: 'admin',
        masterUserPassword: cdk.SecretValue.secretsManager(
          `finefinds-${props.environment}-opensearch-admin-password`
        ),
      },
      logging: {
        slowSearchLogEnabled: true,
        slowIndexLogEnabled: true,
        appLogEnabled: true,
        auditLogEnabled: true,
        slowSearchLogGroup: new logs.LogGroup(this, 'SlowSearchLogs', {
          logGroupName: `/aws/opensearch/${props.environment}/slow-search-logs`,
          retention: props.environment === 'prod' 
            ? logs.RetentionDays.ONE_MONTH 
            : logs.RetentionDays.ONE_WEEK,
          removalPolicy: props.environment === 'prod' 
            ? cdk.RemovalPolicy.RETAIN 
            : cdk.RemovalPolicy.DESTROY,
        }),
        slowIndexLogGroup: new logs.LogGroup(this, 'SlowIndexLogs', {
          logGroupName: `/aws/opensearch/${props.environment}/slow-index-logs`,
          retention: props.environment === 'prod' 
            ? logs.RetentionDays.ONE_MONTH 
            : logs.RetentionDays.ONE_WEEK,
          removalPolicy: props.environment === 'prod' 
            ? cdk.RemovalPolicy.RETAIN 
            : cdk.RemovalPolicy.DESTROY,
        }),
        appLogGroup: new logs.LogGroup(this, 'AppLogs', {
          logGroupName: `/aws/opensearch/${props.environment}/app-logs`,
          retention: props.environment === 'prod' 
            ? logs.RetentionDays.ONE_MONTH 
            : logs.RetentionDays.ONE_WEEK,
          removalPolicy: props.environment === 'prod' 
            ? cdk.RemovalPolicy.RETAIN 
            : cdk.RemovalPolicy.DESTROY,
        }),
        auditLogGroup: new logs.LogGroup(this, 'AuditLogs', {
          logGroupName: `/aws/opensearch/${props.environment}/audit-logs`,
          retention: props.environment === 'prod' 
            ? logs.RetentionDays.ONE_MONTH 
            : logs.RetentionDays.ONE_WEEK,
          removalPolicy: props.environment === 'prod' 
            ? cdk.RemovalPolicy.RETAIN 
            : cdk.RemovalPolicy.DESTROY,
        }),
      },
      removalPolicy: props.environment === 'prod' 
        ? cdk.RemovalPolicy.RETAIN 
        : cdk.RemovalPolicy.DESTROY,
    });

    // Output OpenSearch endpoint
    new cdk.CfnOutput(this, 'OpenSearchEndpoint', {
      value: this.domain.domainEndpoint,
      description: 'OpenSearch Domain Endpoint',
      exportName: `finefinds-${props.environment}-opensearch-endpoint`,
    });

    // Output OpenSearch dashboard URL
    new cdk.CfnOutput(this, 'OpenSearchDashboardUrl', {
      value: `https://${this.domain.domainEndpoint}/_dashboards/`,
      description: 'OpenSearch Dashboard URL',
      exportName: `finefinds-${props.environment}-opensearch-dashboard-url`,
    });
  }
} 