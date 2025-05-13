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

    // Create Backup Resources
    const backup = new BackupConstruct(this, 'Backup', {
      environment: props.config.environment,
      config: props.config,
    });

    // Create WAF Resources
    const waf = new WafConstruct(this, 'Waf', {
      environment: props.config.environment,
      config: props.config,
      loadBalancer: ecs.loadBalancer,
    });

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

    // Add tags to all resources
    cdk.Tags.of(this).add('Environment', props.config.environment);
    cdk.Tags.of(this).add('Project', 'FineFinds');
    cdk.Tags.of(this).add('ManagedBy', 'CDK');
  }
} 