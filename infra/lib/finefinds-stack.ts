import * as cdk from 'aws-cdk-lib';
import { Construct } from 'constructs';
import { BaseConfig } from '../env/base-config';
import { VpcConstruct } from './constructs/vpc';
import { SecretsConstruct } from './constructs/secrets';
import { EcsConstruct } from './constructs/ecs';
import { IamConstruct } from './constructs/iam';
import { CognitoConstruct } from './constructs/cognito';
import { MonitoringConstruct } from './constructs/monitoring';
import { DnsConstruct } from './constructs/dns';
import { BackupConstruct } from './constructs/backup';
import { WafConstruct } from './constructs/waf';
import { CloudFrontConstruct } from './constructs/cloudfront';
import { KmsConstruct } from './constructs/kms';
import { RedisConstruct } from './constructs/redis';
import { AutoShutdownConstruct } from './constructs/auto-shutdown';
import { DynamoDBConstruct } from './constructs/dynamodb';
import { RdsConstruct } from './constructs/rds';
import * as ec2 from 'aws-cdk-lib/aws-ec2';

export interface FineFindsStackProps extends cdk.StackProps {
  config: BaseConfig;
}

export class FineFindsStack extends cdk.Stack {
  constructor(scope: Construct, id: string, props: FineFindsStackProps) {
    super(scope, id, props);

    // Create KMS key for encryption
    const kms = new KmsConstruct(this, 'Kms', {
      environment: props.config.environment,
      config: props.config,
    });

    // Create VPC
    const vpc = new VpcConstruct(this, 'Vpc', {
      environment: props.config.environment,
      config: props.config,
    });

    // Create IAM roles
    const iam = new IamConstruct(this, 'Iam', {
      environment: props.config.environment,
      config: props.config,
    });

    // Create Secrets
    const secrets = new SecretsConstruct(this, 'Secrets', {
      environment: props.config.environment,
      config: props.config,
      kmsKey: kms.key,
    });

    // Create RDS Database
    const rds = new RdsConstruct(this, 'Rds', {
      environment: props.config.environment,
      config: props.config,
      vpc: vpc.vpc,
      kmsKey: kms.key,
    });

    // Create alarm topic
    const alarmTopic = new cdk.aws_sns.Topic(this, 'AlarmTopic', {
      topicName: `finefinds-${props.config.environment}-alarms`,
    });

    // Create Redis ElastiCache
    const redis = new RedisConstruct(this, 'Redis', {
      environment: props.config.environment,
      config: props.config,
      vpc: vpc.vpc,
      alarmTopic,
    });

    // Create ECS Cluster and Services
    const ecs = new EcsConstruct(this, 'Ecs', {
      environment: props.config.environment,
      config: props.config,
      vpc: vpc.vpc,
      taskRole: iam.ecsTaskRole,
      executionRole: iam.ecsExecutionRole,
    });

    // Configure database security groups to allow access from ECS services
    if (props.config.environment === 'prod' && rds.cluster) {
      // For production with Aurora cluster
      rds.cluster.connections.allowDefaultPortFrom(
        ecs.service, 
        'Allow access from ECS service'
      );
    } else if (rds.instance) {
      // For non-production with single instance
      rds.instance.connections.allowDefaultPortFrom(
        ecs.service,
        'Allow access from ECS service'
      );
    }

    // Add database connection environment variables to ECS task definition
    const dbConnectionStringSecret = new cdk.aws_secretsmanager.Secret(this, 'DbConnectionString', {
      secretName: `finefinds-${props.config.environment}-db-connection`,
      description: 'Database connection string for the application',
      generateSecretString: {
        secretStringTemplate: JSON.stringify({
          dbName: 'finefinds',
          engine: 'postgres',
          host: props.config.environment === 'prod' && rds.cluster 
            ? rds.cluster.clusterEndpoint.hostname
            : rds.instance?.instanceEndpoint.hostname,
          port: 5432,
          username: 'postgres', // This should match what's set in your RDS construct
        }),
        generateStringKey: 'password',
      },
    });

    // Add Redis connection details to ECS task
    const redisConnectionSecret = new cdk.aws_secretsmanager.Secret(this, 'RedisConnectionString', {
      secretName: `finefinds-${props.config.environment}-redis-connection`,
      description: 'Redis connection details for the application',
      generateSecretString: {
        secretStringTemplate: JSON.stringify({
          host: redis.cluster.attrRedisEndpointAddress,
          port: redis.cluster.attrRedisEndpointPort,
        }),
        generateStringKey: 'password',
      },
    });
    
    // Set up initial database migration task
    const migrationTask = new cdk.aws_ecs.FargateTaskDefinition(this, 'MigrationTaskDef', {
      memoryLimitMiB: 512,
      cpu: 256,
      taskRole: iam.ecsTaskRole,
      executionRole: iam.ecsExecutionRole,
    });
    
    migrationTask.addContainer('MigrationContainer', {
      image: cdk.aws_ecs.ContainerImage.fromRegistry('891076991993.dkr.ecr.us-east-1.amazonaws.com/finefinds-base/node-20-alpha:latest'),
      command: ['npm', 'run', 'migration:run'],
      logging: cdk.aws_ecs.LogDrivers.awsLogs({
        streamPrefix: 'db-migration',
        logGroup: new cdk.aws_logs.LogGroup(this, 'MigrationLogGroup', {
          logGroupName: `/finefinds/${props.config.environment}/db-migration`,
          retention: props.config.environment === 'prod' 
            ? cdk.aws_logs.RetentionDays.ONE_MONTH 
            : cdk.aws_logs.RetentionDays.ONE_DAY,
          removalPolicy: props.config.environment === 'prod' 
            ? cdk.RemovalPolicy.RETAIN 
            : cdk.RemovalPolicy.DESTROY,
        }),
      }),
      environment: {
        NODE_ENV: props.config.environment,
      },
      secrets: {
        DATABASE_URL: cdk.aws_ecs.Secret.fromSecretsManager(dbConnectionStringSecret),
        REDIS_URL: cdk.aws_ecs.Secret.fromSecretsManager(redisConnectionSecret),
      },
    });
    
    // Output important resource information
    new cdk.CfnOutput(this, 'DatabaseEndpoint', {
      value: props.config.environment === 'prod' && rds.cluster 
        ? rds.cluster.clusterEndpoint.hostname
        : rds.instance?.instanceEndpoint.hostname || 'No database endpoint available',
      description: 'Database endpoint',
      exportName: `finefinds-${props.config.environment}-app-db-endpoint`,
    });
    
    new cdk.CfnOutput(this, 'DatabaseSecretArn', {
      value: props.config.environment === 'prod' && rds.cluster 
        ? rds.cluster.secret?.secretArn || 'No secret available'
        : rds.instance?.secret?.secretArn || 'No secret available',
      description: 'Database credentials secret ARN',
      exportName: `finefinds-${props.config.environment}-app-db-secret-arn`,
    });
    
    new cdk.CfnOutput(this, 'RedisEndpoint', {
      value: redis.cluster.attrRedisEndpointAddress,
      description: 'Redis endpoint',
      exportName: `finefinds-${props.config.environment}-app-redis-endpoint`,
    });

    // Create Cognito User Pools
    const cognito = new CognitoConstruct(this, 'Cognito', {
      environment: props.config.environment,
      config: props.config,
    });

    // Create Monitoring Resources
    const monitoring = new MonitoringConstruct(this, 'Monitoring', {
      environment: props.config.environment,
      config: props.config,
      ecsCluster: ecs.cluster,
      alarmTopic,
    });

    // Create DNS Resources
    const dns = new DnsConstruct(this, 'Dns', {
      environment: props.config.environment,
      config: props.config,
      loadBalancer: ecs.loadBalancer,
      domainName: props.config.dns.domainName,
    });

    // Create Backup Resources (only for production)
    if (props.config.environment === 'prod') {
      const backup = new BackupConstruct(this, 'Backup', {
        environment: props.config.environment,
        config: props.config,
      });
    }

    // Create WAF Resources (only for production)
    if (props.config.environment === 'prod') {
      const waf = new WafConstruct(this, 'Waf', {
        environment: props.config.environment,
        config: props.config,
        loadBalancer: ecs.loadBalancer,
      });
    }

    // Create CloudFront Resources
    const cloudfront = new CloudFrontConstruct(this, 'CloudFront', {
      environment: props.config.environment,
      config: props.config,
      loadBalancer: ecs.loadBalancer,
      uploadsBucket: new cdk.aws_s3.Bucket(this, 'UploadsBucket', {
        bucketName: `finefinds-${props.config.environment}-uploads`,
        versioned: props.config.s3.versioned,
        encryption: cdk.aws_s3.BucketEncryption.S3_MANAGED,
        blockPublicAccess: cdk.aws_s3.BlockPublicAccess.BLOCK_ALL,
        removalPolicy: props.config.environment === 'prod' 
          ? cdk.RemovalPolicy.RETAIN 
          : cdk.RemovalPolicy.DESTROY,
      }),
    });
    
    // Create DynamoDB tables if needed
    // Note: Only include this if your application requires DynamoDB
    // This is optimized for cost in non-production environments
    if (props.config.enableDynamoDB ?? false) {
      const dynamodb = new DynamoDBConstruct(this, 'DynamoDB', {
        environment: props.config.environment,
        config: props.config,
        kmsKey: kms.key,
      });
    }

    // Add tags to all resources
    cdk.Tags.of(this).add('Environment', props.config.environment);
    cdk.Tags.of(this).add('Project', 'FineFinds');
    cdk.Tags.of(this).add('ManagedBy', 'CDK');
    
    // Add auto-shutdown for non-production environments
    if (['dev', 'sandbox', 'qa'].includes(props.config.environment)) {
      const autoShutdown = new AutoShutdownConstruct(this, 'AutoShutdown', {
        environment: props.config.environment,
        config: props.config,
        cluster: ecs.cluster,
        service: ecs.service,
      });
    }
  }
} 