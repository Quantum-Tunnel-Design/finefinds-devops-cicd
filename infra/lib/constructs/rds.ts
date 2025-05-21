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
  public readonly instance: rds.DatabaseInstance;
  public readonly cluster?: rds.DatabaseCluster;
  public readonly securityGroup: ec2.SecurityGroup;
  public readonly parameterGroup: rds.ParameterGroup;

  constructor(scope: Construct, id: string, props: RdsConstructProps) {
    super(scope, id);

    // Create security group for RDS
    this.securityGroup = new ec2.SecurityGroup(this, 'DbSecurityGroup', {
      vpc: props.vpc,
      description: 'Security group for RDS',
      allowAllOutbound: true,
    });

    // Allow inbound PostgreSQL access from ECS tasks
    this.securityGroup.addIngressRule(
      ec2.Peer.ipv4(props.vpc.vpcCidrBlock),
      ec2.Port.tcp(5432),
      'Allow PostgreSQL access from within VPC'
    );

    if (props.environment === 'prod') {
      // For production, use Aurora PostgreSQL cluster
      this.parameterGroup = new rds.ParameterGroup(this, 'ParameterGroup', {
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
          'password_encryption': 'scram-sha-256',
          'ssl': '1',
        },
      });

      // Create Aurora RDS cluster for production
      this.cluster = new rds.DatabaseCluster(this, 'Database', {
        engine: rds.DatabaseClusterEngine.auroraPostgres({
          version: rds.AuroraPostgresEngineVersion.VER_13_4,
        }),
        instanceProps: {
          instanceType: ec2.InstanceType.of(
            ec2.InstanceClass.T3,
            ec2.InstanceSize.MICRO
          ),
          vpc: props.vpc,
          vpcSubnets: {
            subnetType: ec2.SubnetType.PRIVATE_WITH_EGRESS,
          },
          securityGroups: [this.securityGroup],
          parameterGroup: this.parameterGroup,
          enablePerformanceInsights: true,
          performanceInsightRetention: rds.PerformanceInsightRetention.DEFAULT,
        },
        instances: 2,
        defaultDatabaseName: 'finefinds',
        storageEncrypted: true,
        storageEncryptionKey: props.kmsKey,
        backup: {
          retention: cdk.Duration.days(props.config.rds.backupRetention),
          preferredWindow: '03:00-04:00',
        },
        monitoringInterval: cdk.Duration.seconds(60),
        monitoringRole: new cdk.aws_iam.Role(this, 'MonitoringRole', {
          assumedBy: new cdk.aws_iam.ServicePrincipal('monitoring.rds.amazonaws.com'),
          inlinePolicies: {
            'RDSMonitoringPermissions': new cdk.aws_iam.PolicyDocument({
              statements: [
                new cdk.aws_iam.PolicyStatement({
                  actions: [
                    'cloudwatch:PutMetricData',
                    'logs:CreateLogGroup',
                    'logs:CreateLogStream',
                    'logs:PutLogEvents',
                    'logs:DescribeLogStreams',
                    'rds:DescribeDBInstances',
                    'rds:DescribeDBClusters',
                    'rds:DescribeDBLogFiles',
                    'rds:DescribeDBParameters',
                    'rds:DescribeDBSnapshotAttributes',
                    'rds:DescribeDBSnapshots',
                    'rds:DescribeDBEngineVersions'
                  ],
                  resources: ['*'],
                })
              ],
            })
          }
        }),
        cloudwatchLogsExports: ['postgresql'],
        cloudwatchLogsRetention: logs.RetentionDays.ONE_MONTH,
        removalPolicy: cdk.RemovalPolicy.RETAIN,
        deletionProtection: props.config.rds.deletionProtection,
        copyTagsToSnapshot: true,
        preferredMaintenanceWindow: 'sun:04:00-sun:05:00',
      });

      // Output Aurora cluster endpoint and secret
      new cdk.CfnOutput(this, 'ClusterEndpoint', {
        value: this.cluster.clusterEndpoint.hostname,
        description: 'RDS Cluster Endpoint',
        exportName: `finefinds-${props.environment}-db-endpoint`,
      });

      new cdk.CfnOutput(this, 'ClusterSecretArn', {
        value: this.cluster.secret!.secretArn,
        description: 'RDS Cluster Secret ARN',
        exportName: `finefinds-${props.environment}-db-secret-arn`,
      });
    } else {
      // For non-production environments, use single-instance PostgreSQL
      this.parameterGroup = new rds.ParameterGroup(this, 'ParameterGroup', {
        engine: rds.DatabaseInstanceEngine.postgres({
          version: rds.PostgresEngineVersion.VER_13,
        }),
        parameters: {
          'ssl': '1',
          'log_connections': '1',
          'log_disconnections': '1',
          'log_statement': 'ddl',
          'log_min_duration_statement': '1000',
          'password_encryption': 'scram-sha-256',
        },
      });

      // Create single-instance RDS PostgreSQL for dev/test
      this.instance = new rds.DatabaseInstance(this, 'Database', {
        engine: rds.DatabaseInstanceEngine.postgres({
          version: rds.PostgresEngineVersion.VER_13,
        }),
        instanceType: ec2.InstanceType.of(ec2.InstanceClass.T3, ec2.InstanceSize.MICRO),
        vpc: props.vpc,
        vpcSubnets: {
          subnetType: ec2.SubnetType.PRIVATE_WITH_EGRESS,
        },
        securityGroups: [this.securityGroup],
        parameterGroup: this.parameterGroup,
        databaseName: 'finefinds',
        storageEncrypted: true,
        storageEncryptionKey: props.kmsKey,
        allocatedStorage: props.config.rds.allocatedStorage,
        maxAllocatedStorage: props.config.rds.maxAllocatedStorage,
        storageType: rds.StorageType.GP2,
        backupRetention: cdk.Duration.days(props.config.rds.backupRetention),
        cloudwatchLogsExports: ['postgresql'],
        cloudwatchLogsRetention: logs.RetentionDays.ONE_DAY,
        removalPolicy: cdk.RemovalPolicy.DESTROY,
        deletionProtection: props.config.rds.deletionProtection,
        copyTagsToSnapshot: true,
        preferredMaintenanceWindow: 'sun:04:00-sun:05:00',
        credentials: rds.Credentials.fromGeneratedSecret('postgres'),
        monitoringInterval: cdk.Duration.seconds(0),
        autoMinorVersionUpgrade: true,
      });

      // Output single instance endpoint and secret
      new cdk.CfnOutput(this, 'InstanceEndpoint', {
        value: this.instance.instanceEndpoint.hostname,
        description: 'RDS Instance Endpoint',
        exportName: `finefinds-${props.environment}-db-endpoint`,
      });

      new cdk.CfnOutput(this, 'InstanceSecretArn', {
        value: this.instance.secret!.secretArn,
        description: 'RDS Instance Secret ARN',
        exportName: `finefinds-${props.environment}-db-secret-arn`,
      });
    }
  }
} 