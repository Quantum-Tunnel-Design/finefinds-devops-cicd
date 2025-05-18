import * as cdk from 'aws-cdk-lib';
import { Construct } from 'constructs';
import { BaseConfig } from '../env/base-config';
import { VpcConstruct } from './constructs/vpc';
import { SecretsConstruct } from './constructs/secrets';
import { EcsConstruct } from './constructs/ecs';
import { IamConstruct } from './constructs/iam';
import { CognitoConstruct } from './constructs/cognito';
import { MonitoringConstruct } from './constructs/monitoring';
import { BackupConstruct } from './constructs/backup';
import { WafConstruct } from './constructs/waf';
import { CloudFrontConstruct } from './constructs/cloudfront';
import { KmsConstruct } from './constructs/kms';
import { RedisConstruct } from './constructs/redis';
import { AutoShutdownConstruct } from './constructs/auto-shutdown';
import { DynamoDBConstruct } from './constructs/dynamodb';
import { RdsConstruct } from './constructs/rds';
import { MigrationTaskConstruct } from './constructs/migration-task';
import { AmplifyConstruct } from './constructs/amplify';
import * as secretsmanager from 'aws-cdk-lib/aws-secretsmanager';
import * as ec2 from 'aws-cdk-lib/aws-ec2';

/**
 * Creates a secret if it doesn't exist, or imports it if it does
 * This is a hybrid approach that works with both new and existing environments
 * Influenced by the patterns in ExistingConstruct
 */
function getOrCreateSecret(
  scope: Construct,
  id: string,
  secretName: string,
  props: secretsmanager.SecretProps
): secretsmanager.ISecret {
  // First, check if we can import the secret
  // Use a pattern similar to ExistingConstruct where we try to reference existing resources
  try {
    // Try to create the secret with RETAIN policy to prevent accidental deletion
    const newSecret = new secretsmanager.Secret(scope, id, {
      ...props,
      secretName: secretName,
    });
    newSecret.applyRemovalPolicy(cdk.RemovalPolicy.RETAIN);
    return newSecret;
  } catch (e) {
    // If the creation fails (likely because the secret already exists),
    // fall back to importing the existing secret, similar to how ExistingConstruct imports resources
    console.log(`Secret ${secretName} already exists, importing it instead`);
    return secretsmanager.Secret.fromSecretNameV2(scope, `Existing${id}`, secretName);
  }
}

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
    
    // Import the existing database connection secret (don't try to create it)
    const dbConnectionStringSecret = secretsmanager.Secret.fromSecretNameV2(
      this, 
      'DbConnectionString',
      `finefinds-${props.config.environment}-db-connection`
    );

    // Import the existing Redis connection secret (don't try to create it)
    const redisConnectionSecret = secretsmanager.Secret.fromSecretNameV2(
      this,
      'RedisConnectionString',
      `finefinds-${props.config.environment}-redis-connection`
    );
    
    // Update the database connection secret once the RDS instance is available
    // Use a custom resource to avoid circular dependencies
    if (props.config.environment === 'prod' && rds.cluster) {
      // For production, use the Aurora cluster
      const updateDbSecret = new cdk.custom_resources.AwsCustomResource(this, 'UpdateDbConnectionSecret', {
        onCreate: {
          service: 'SecretsManager',
          action: 'updateSecret',
          parameters: {
            SecretId: dbConnectionStringSecret.secretArn,
            SecretString: cdk.Lazy.string({
              produce: () => {
                return JSON.stringify({
                  dbName: 'finefinds',
                  engine: 'postgres',
                  host: rds.cluster?.clusterEndpoint.hostname,
                  port: 5432,
                  username: 'postgres', // This should match RDS credentials
                  password: '{{resolve:secretsmanager:' + dbConnectionStringSecret.secretArn + ':SecretString:password}}',
                });
              }
            }),
          },
          physicalResourceId: cdk.custom_resources.PhysicalResourceId.of('DbSecretUpdate-' + Date.now().toString()),
        },
        onUpdate: {
          service: 'SecretsManager',
          action: 'updateSecret',
          parameters: {
            SecretId: dbConnectionStringSecret.secretArn,
            SecretString: cdk.Lazy.string({
              produce: () => {
                return JSON.stringify({
                  dbName: 'finefinds',
                  engine: 'postgres',
                  host: rds.cluster?.clusterEndpoint.hostname,
                  port: 5432,
                  username: 'postgres',
                  password: '{{resolve:secretsmanager:' + dbConnectionStringSecret.secretArn + ':SecretString:password}}',
                });
              }
            }),
          },
          physicalResourceId: cdk.custom_resources.PhysicalResourceId.of('DbSecretUpdate-' + Date.now().toString()),
        },
        policy: cdk.custom_resources.AwsCustomResourcePolicy.fromSdkCalls({
          resources: cdk.custom_resources.AwsCustomResourcePolicy.ANY_RESOURCE,
        }),
      });
      
      // Ensure the custom resource runs after RDS is created
      updateDbSecret.node.addDependency(rds.cluster);
      
    } else if (rds.instance) {
      // For non-production, use single instance
      const updateDbSecret = new cdk.custom_resources.AwsCustomResource(this, 'UpdateDbConnectionSecret', {
        onCreate: {
          service: 'SecretsManager',
          action: 'updateSecret',
          parameters: {
            SecretId: dbConnectionStringSecret.secretArn,
            SecretString: cdk.Lazy.string({
              produce: () => {
                return JSON.stringify({
                  dbName: 'finefinds',
                  engine: 'postgres',
                  host: rds.instance.instanceEndpoint.hostname,
                  port: 5432,
                  username: 'postgres', // This should match RDS credentials
                  password: '{{resolve:secretsmanager:' + dbConnectionStringSecret.secretArn + ':SecretString:password}}',
                });
              }
            }),
          },
          physicalResourceId: cdk.custom_resources.PhysicalResourceId.of('DbSecretUpdate-' + Date.now().toString()),
        },
        onUpdate: {
          service: 'SecretsManager',
          action: 'updateSecret',
          parameters: {
            SecretId: dbConnectionStringSecret.secretArn,
            SecretString: cdk.Lazy.string({
              produce: () => {
                return JSON.stringify({
                  dbName: 'finefinds',
                  engine: 'postgres',
                  host: rds.instance.instanceEndpoint.hostname,
                  port: 5432,
                  username: 'postgres',
                  password: '{{resolve:secretsmanager:' + dbConnectionStringSecret.secretArn + ':SecretString:password}}',
                });
              }
            }),
          },
          physicalResourceId: cdk.custom_resources.PhysicalResourceId.of('DbSecretUpdate-' + Date.now().toString()),
        },
        policy: cdk.custom_resources.AwsCustomResourcePolicy.fromSdkCalls({
          resources: cdk.custom_resources.AwsCustomResourcePolicy.ANY_RESOURCE,
        }),
      });
      
      // Ensure the custom resource runs after RDS is created
      updateDbSecret.node.addDependency(rds.instance);
    }

    // Create ECS Cluster and Services
    const ecs = new EcsConstruct(this, 'Ecs', {
      environment: props.config.environment,
      config: props.config,
      vpc: vpc.vpc,
      taskRole: iam.ecsTaskRole,
      executionRole: iam.ecsExecutionRole,
    });
    
    // Create migration task definition
    const migrationTask = new MigrationTaskConstruct(this, 'MigrationTask', {
      environment: props.config.environment,
      config: props.config,
      vpc: vpc.vpc,
      taskRole: iam.ecsTaskRole,
      executionRole: iam.ecsExecutionRole,
    });

    // Add dependencies to ensure proper creation order
    if (props.config.environment === 'prod' && rds.cluster) {
      ecs.service.node.addDependency(rds.cluster);
      migrationTask.taskDefinition.node.addDependency(rds.cluster);
    } else if (rds.instance) {
      ecs.service.node.addDependency(rds.instance);
      migrationTask.taskDefinition.node.addDependency(rds.instance);
    }
    ecs.service.node.addDependency(dbConnectionStringSecret);
    migrationTask.taskDefinition.node.addDependency(dbConnectionStringSecret);
    ecs.service.node.addDependency(redisConnectionSecret);

    // Output subnet IDs for migration task
    const privateSubnets = vpc.vpc.selectSubnets({
      subnetType: ec2.SubnetType.PRIVATE_ISOLATED
    }).subnetIds;
    const subnetIdsOutput = new cdk.CfnOutput(this, 'MigrationSubnetIds', {
      value: privateSubnets.length > 0 ? privateSubnets.join(',') : 'No private subnets available',
      description: 'Private subnet IDs for migration task',
      exportName: `finefinds-${props.config.environment}-migration-task-subnet-ids`,
    });
    subnetIdsOutput.node.addDependency(vpc.vpc);

    // Create security group for migration task
    const migrationSecurityGroup = new ec2.SecurityGroup(this, 'MigrationTaskSecurityGroup', {
      vpc: vpc.vpc,
      description: 'Security group for database migration task',
      allowAllOutbound: true,
    });

    // Allow inbound access from within the VPC
    migrationSecurityGroup.addIngressRule(
      ec2.Peer.ipv4(vpc.vpc.vpcCidrBlock),
      ec2.Port.allTcp(),
      'Allow all inbound from within VPC'
    );

    // Allow inbound access from the security group to the database
    if (props.config.environment === 'prod' && rds.cluster) {
      rds.cluster.connections.allowDefaultPortFrom(
        migrationSecurityGroup,
        'Allow access from migration task'
      );
    } else if (rds.instance) {
      rds.instance.connections.allowDefaultPortFrom(
        migrationSecurityGroup,
        'Allow access from migration task'
      );
    }

    // Output security group ID for migration task
    new cdk.CfnOutput(this, 'MigrationTaskSecurityGroupId', {
      value: migrationSecurityGroup.securityGroupId,
      description: 'Security group ID for migration task',
      exportName: `finefinds-${props.config.environment}-migration-task-sg-id`,
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

    // Output CloudFront distribution domain name for manual DNS configuration in Dreamhost
    new cdk.CfnOutput(this, 'CloudFrontDomainName', {
      value: cloudfront.distribution.distributionDomainName,
      description: 'CloudFront distribution domain name for Dreamhost DNS configuration',
      exportName: `finefinds-${props.config.environment}-cf-domain-name`,
    });

    // Output load balancer DNS name for manual DNS configuration in Dreamhost
    new cdk.CfnOutput(this, 'LoadBalancerDnsName', {
      value: ecs.loadBalancer.loadBalancerDnsName,
      description: 'Load Balancer DNS name for Dreamhost DNS configuration',
      exportName: `finefinds-${props.config.environment}-lb-dns-name`,
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

    // Create DynamoDB tables if needed
    if (props.config.environment === 'prod' || props.config.environment === 'uat') {
      const dynamodb = new DynamoDBConstruct(this, 'DynamoDB', {
        environment: props.config.environment,
        config: props.config,
        kmsKey: kms.key,
      });
    }

    // Create Amplify apps for frontend applications
    const amplify = new AmplifyConstruct(this, 'Amplify', {
      environment: props.config.environment,
      config: props.config,
    });

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