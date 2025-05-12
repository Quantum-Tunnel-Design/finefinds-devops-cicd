import * as cdk from 'aws-cdk-lib';
import * as ec2 from 'aws-cdk-lib/aws-ec2';
import * as rds from 'aws-cdk-lib/aws-rds';
import * as kms from 'aws-cdk-lib/aws-kms';
import * as logs from 'aws-cdk-lib/aws-logs';
import { Construct } from 'constructs';
import { BaseConfig } from '../../env/base-config';

export interface RdsConstructProps {
  environment: string;
  config: BaseConfig;
  vpc: ec2.Vpc;
  kmsKey: kms.Key;
}

export class RdsConstruct extends Construct {
  public readonly cluster: rds.DatabaseCluster;

  constructor(scope: Construct, id: string, props: RdsConstructProps) {
    super(scope, id);

    // Create security group for RDS
    const securityGroup = new ec2.SecurityGroup(this, 'DbSecurityGroup', {
      vpc: props.vpc,
      description: 'Security group for RDS cluster',
      allowAllOutbound: true,
    });

    // Allow inbound PostgreSQL access from ECS tasks
    securityGroup.addIngressRule(
      ec2.Peer.ipv4(props.vpc.vpcCidrBlock),
      ec2.Port.tcp(5432),
      'Allow PostgreSQL access from within VPC'
    );

    // Create parameter group
    const parameterGroup = new rds.ParameterGroup(this, 'ParameterGroup', {
      engine: rds.DatabaseClusterEngine.auroraPostgres({
        version: rds.AuroraPostgresEngineVersion.VER_13_4,
      }),
      parameters: {
        'rds.force_ssl': '1',
        'log_connections': '1',
        'log_disconnections': '1',
        'log_statement': 'ddl',
        'log_min_duration_statement': '1000',
        'log_rotation_age': '1440',
        'log_rotation_size': '102400',
      },
    });

    // Create RDS cluster
    this.cluster = new rds.DatabaseCluster(this, 'Database', {
      engine: rds.DatabaseClusterEngine.auroraPostgres({
        version: rds.AuroraPostgresEngineVersion.VER_13_4,
      }),
      instanceProps: {
        instanceType: props.environment === 'prod' 
          ? ec2.InstanceType.of(
              ec2.InstanceClass[props.config.rds.instanceClass as keyof typeof ec2.InstanceClass],
              ec2.InstanceSize[props.config.rds.instanceSize as keyof typeof ec2.InstanceSize]
            )
          : ec2.InstanceType.of(ec2.InstanceClass.T3, ec2.InstanceSize.SMALL),
        vpc: props.vpc,
        vpcSubnets: {
          subnetType: props.environment === 'prod' 
            ? ec2.SubnetType.PRIVATE_WITH_EGRESS 
            : ec2.SubnetType.PRIVATE_ISOLATED,
        },
        securityGroups: [securityGroup],
        parameterGroup,
        performanceInsightRetention: props.environment === 'prod' && props.config.rds.performanceInsights
          ? rds.PerformanceInsightRetention.DEFAULT
          : undefined,
        enablePerformanceInsights: props.environment === 'prod' && props.config.rds.performanceInsights,
      },
      instances: props.environment === 'prod' ? 2 : 1,
      defaultDatabaseName: 'finefinds',
      storageEncrypted: true,
      storageEncryptionKey: props.kmsKey,
      backup: {
        retention: cdk.Duration.days(props.environment === 'prod' ? props.config.rds.backupRetentionDays : 1),
        preferredWindow: '03:00-04:00',
      },
      monitoringInterval: props.environment === 'prod' ? cdk.Duration.seconds(60) : cdk.Duration.seconds(0),
      monitoringRole: props.environment === 'prod' ? 
        new cdk.aws_iam.Role(this, 'MonitoringRole', {
          assumedBy: new cdk.aws_iam.ServicePrincipal('monitoring.rds.amazonaws.com'),
          managedPolicies: [
            cdk.aws_iam.ManagedPolicy.fromAwsManagedPolicyName(
              'service-role/AmazonRDSEnhancedMonitoringRole'
            ),
          ],
        }) : undefined,
      cloudwatchLogsExports: ['postgresql'],
      cloudwatchLogsRetention: props.environment === 'prod' 
        ? logs.RetentionDays.ONE_MONTH 
        : logs.RetentionDays.ONE_WEEK,
      removalPolicy: props.environment === 'prod' 
        ? cdk.RemovalPolicy.RETAIN 
        : cdk.RemovalPolicy.DESTROY,
      deletionProtection: props.environment === 'prod',
      copyTagsToSnapshot: true,
      preferredMaintenanceWindow: 'sun:04:00-sun:05:00',
      vpc: props.vpc,
    });

    // Output cluster endpoint and secret ARN
    new cdk.CfnOutput(this, 'ClusterEndpoint', {
      value: this.cluster.clusterEndpoint.hostname,
      description: 'RDS Cluster Endpoint',
      exportName: `finefinds-${props.environment}-db-endpoint`,
    });

    new cdk.CfnOutput(this, 'SecretArn', {
      value: this.cluster.secret!.secretArn,
      description: 'RDS Secret ARN',
      exportName: `finefinds-${props.environment}-db-secret-arn`,
    });
  }
} 