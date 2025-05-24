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
import { BastionConstruct } from './constructs/bastion';
import { SesConstruct } from './constructs/ses';
import * as secretsmanager from 'aws-cdk-lib/aws-secretsmanager';
import * as ec2 from 'aws-cdk-lib/aws-ec2';
import * as iamcdk from 'aws-cdk-lib/aws-iam';

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

    // Policy from SecretsConstruct grants ECS Task Role access to all its managed secrets
    iam.ecsTaskRole.addToPolicy(secrets.taskRolePolicy);
    // Also grant the same permissions to the ECS Task Execution Role
    iam.ecsExecutionRole.addToPolicy(secrets.taskRolePolicy);

    // Add SES sending permissions to ECS Task Role
    iam.ecsTaskRole.addToPrincipalPolicy(new iamcdk.PolicyStatement({
      actions: ['ses:SendEmail', 'ses:SendRawEmail'],
      resources: [
        // ARN for the SES Identity (domain)
        `arn:aws:ses:${cdk.Stack.of(this).region}:${cdk.Stack.of(this).account}:identity/${props.config.ses.domainName}`,
        // ARN for the SES Configuration Set
        `arn:aws:ses:${cdk.Stack.of(this).region}:${cdk.Stack.of(this).account}:configuration-set/*`, // Using wildcard as CFN created config set name might have suffix
      ],
      effect: iamcdk.Effect.ALLOW,
    }));

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

    // Create SES Construct
    const ses = new SesConstruct(this, 'Ses', {
      config: props.config.ses,
      envIdentifier: props.config.environment,
    });

    // Update the database connection secret (contents of secrets.databaseSecret)
    // This custom resource updates the placeholder secret created by SecretsConstruct
    // with the actual connection details from the RDS instance/cluster.
    let rdsEndpointHost: string | undefined;
    let rdsSecretForConnectionString: secretsmanager.ISecret | undefined;

    if (props.config.environment === 'prod' && rds.cluster && rds.cluster.secret) {
      rdsEndpointHost = rds.cluster.clusterEndpoint.hostname;
      rdsSecretForConnectionString = rds.cluster.secret;
    } else if (rds.instance && rds.instance.secret) {
      rdsEndpointHost = rds.instance.instanceEndpoint.hostname;
      rdsSecretForConnectionString = rds.instance.secret;
    }

    if (rdsEndpointHost && rdsSecretForConnectionString) {
      const updateDbSecret = new cdk.custom_resources.AwsCustomResource(this, 'UpdateDbConnectionSecret', {
        onCreate: {
          service: 'SecretsManager',
          action: 'putSecretValue',
          parameters: {
            SecretId: secrets.databaseSecret.secretName,
            SecretString: cdk.Lazy.string({
              produce: () => {
                const username = rdsSecretForConnectionString!.secretValueFromJson('username').unsafeUnwrap();
                const password = rdsSecretForConnectionString!.secretValueFromJson('password').unsafeUnwrap();
                return JSON.stringify({
                  dbName: 'finefinds', // Or your actual DB name
                  engine: 'postgres',
                  host: rdsEndpointHost,
                  port: 5432,
                  username: username,
                  password: password,
                  connectionString: `postgresql://${username}:${password}@${rdsEndpointHost}:5432/finefinds`,
                });
              }
            }),
          },
          physicalResourceId: cdk.custom_resources.PhysicalResourceId.of('DbFixedSecretUpdate-' + Date.now().toString()),
        },
        onUpdate: { // Also update if stack updates
          service: 'SecretsManager',
          action: 'putSecretValue',
          parameters: {
            SecretId: secrets.databaseSecret.secretName,
            SecretString: cdk.Lazy.string({
              produce: () => {
                const username = rdsSecretForConnectionString!.secretValueFromJson('username').unsafeUnwrap();
                const password = rdsSecretForConnectionString!.secretValueFromJson('password').unsafeUnwrap();
                return JSON.stringify({
                  dbName: 'finefinds',
                  engine: 'postgres',
                  host: rdsEndpointHost,
                  port: 5432,
                  username: username,
                  password: password,
                  connectionString: `postgresql://${username}:${password}@${rdsEndpointHost}:5432/finefinds`,
                });
              }
            }),
          },
          physicalResourceId: cdk.custom_resources.PhysicalResourceId.of('DbFixedSecretUpdate-' + Date.now().toString()),
        },
        policy: cdk.custom_resources.AwsCustomResourcePolicy.fromStatements([
          new iamcdk.PolicyStatement({
            actions: ['secretsmanager:PutSecretValue', 'secretsmanager:DescribeSecret'],
            resources: [secrets.databaseSecret.secretArn],
            effect: iamcdk.Effect.ALLOW,
          }),
          new iamcdk.PolicyStatement({
            actions: ['secretsmanager:GetSecretValue', 'secretsmanager:DescribeSecret'],
            resources: [rdsSecretForConnectionString.secretArn],
            effect: iamcdk.Effect.ALLOW,
          })
        ]),
      });
      // Ensure this custom resource runs after RDS and its secret are available
      if (props.config.environment === 'prod' && rds.cluster) updateDbSecret.node.addDependency(rds.cluster);
      if (props.config.environment !== 'prod' && rds.instance) updateDbSecret.node.addDependency(rds.instance);
      if (rdsSecretForConnectionString) updateDbSecret.node.addDependency(rdsSecretForConnectionString);
      updateDbSecret.node.addDependency(secrets.databaseSecret); // Depends on the placeholder secret object
    }

    // Create ECS Cluster and Services
    const ecsService = new EcsConstruct(this, 'Ecs', {
      environment: props.config.environment,
      config: props.config, 
      vpc: vpc.vpc,
      taskRole: iam.ecsTaskRole,
      executionRole: iam.ecsExecutionRole,
      secrets: { 
        JWT_SECRET_VALUE: cdk.aws_ecs.Secret.fromSecretsManager(secrets.jwtSecret),
        SMTP_SECRET_VALUE: cdk.aws_ecs.Secret.fromSecretsManager(secrets.smtpSecret),
        // If Sentry/Session secrets were defined in this stack (e.g., sentryDsnSecret, sessionSecret):
        // SENTRY_DSN_VALUE: cdk.aws_ecs.Secret.fromSecretsManager(sentryDsnSecret!),
        // SESSION_SECRET_VALUE: cdk.aws_ecs.Secret.fromSecretsManager(sessionSecret!),
      },
      additionalEnvironment: { 
        APP_ENV: props.config.environment,
        REGION: props.config.region,
        DB_SECRET_NAME: secrets.databaseSecret.secretName,
        REDIS_SECRET_NAME: secrets.redisSecret.secretName,
        SMTP_HOST: props.config.smtp.host, 
        SMTP_PORT: props.config.smtp.port.toString(),
        SMTP_USER: props.config.smtp.username,
        // SMTP_PASS_SECRET_NAME is not needed if app uses SMTP_SECRET_VALUE
        LOG_LEVEL: props.config.environment === 'prod' ? 'info' : 'debug',
        OPENSEARCH_ENDPOINT: props.config.opensearch.endpoint,
        CLIENT_URL: props.config.environment === 'prod' ? 'https://finefindslk.com' : `https://${props.config.environment}.finefindslk.com`,
        ADMIN_URL: props.config.environment === 'prod' ? 'https://admin.finefindslk.com' : `https://admin-${props.config.environment}.finefindslk.com`,
        SES_CONFIGURATION_SET_NAME: ses.configurationSetName,
        SES_FROM_EMAIL: props.config.ses.fromEmail,
        SES_WELCOME_TEMPLATE_NAME: props.config.ses.templates.welcome.templateName,
        SES_WELCOME_TEMPLATE_SUBJECT: props.config.ses.templates.welcome.subject,
        SES_PASSWORD_RESET_TEMPLATE_NAME: props.config.ses.templates.passwordReset.templateName,
        SES_PASSWORD_RESET_TEMPLATE_SUBJECT: props.config.ses.templates.passwordReset.subject,
        SES_EMAIL_VERIFICATION_TEMPLATE_NAME: props.config.ses.templates.emailVerification.templateName,
        SES_EMAIL_VERIFICATION_TEMPLATE_SUBJECT: props.config.ses.templates.emailVerification.subject,
      },
    });

    // Create migration task definition
    const migrationTask = new MigrationTaskConstruct(this, 'MigrationTask', {
      environment: props.config.environment,
      config: props.config,
      vpc: vpc.vpc,
      taskRole: iam.ecsTaskRole, // Pass the main task role
      executionRole: iam.ecsExecutionRole, // Pass the main execution role
      dbConnectionSecret: secrets.databaseSecret, // Pass the specific DB connection secret
    });

    // Add dependencies to ensure proper creation order
    if (props.config.environment === 'prod' && rds.cluster) {
      ecsService.service.node.addDependency(rds.cluster);
      migrationTask.taskDefinition.node.addDependency(rds.cluster);
    } else if (rds.instance) {
      ecsService.service.node.addDependency(rds.instance);
      migrationTask.taskDefinition.node.addDependency(rds.instance);
    }
    ecsService.service.node.addDependency(secrets.redisSecret);
    migrationTask.taskDefinition.node.addDependency(secrets.databaseSecret); // Migration depends on DB secret

    // Output subnet IDs for migration task
    const privateSubnets = vpc.vpc.selectSubnets({
      subnetType: ec2.SubnetType.PRIVATE_WITH_EGRESS
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

    migrationSecurityGroup.addIngressRule(
      ec2.Peer.ipv4(vpc.vpc.vpcCidrBlock),
      ec2.Port.allTcp(),
      'Allow all inbound from within VPC'
    );

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

    new cdk.CfnOutput(this, 'MigrationTaskSecurityGroupId', {
      value: migrationSecurityGroup.securityGroupId,
      description: 'Security group ID for migration task',
      exportName: `finefinds-${props.config.environment}-migration-task-sg-id`,
    });

    if (props.config.environment === 'prod' && rds.cluster) {
      rds.cluster.connections.allowDefaultPortFrom(
        ecsService.service, 
        'Allow access from ECS service'
      );
    } else if (rds.instance) {
      rds.instance.connections.allowDefaultPortFrom(
        ecsService.service,
        'Allow access from ECS service'
      );
    }

    const cognito = new CognitoConstruct(this, 'Cognito', {
      environment: props.config.environment,
      config: props.config,
    });
    
    // Custom Resource to populate the Cognito Config Secret
    const cognitoSecretJson: { [key: string]: string } = {
      clientUserPoolId: cognito.clientUserPool.userPoolId,
      clientUserPoolClientId: cognito.clientUserPoolClient.userPoolClientId,
      adminUserPoolId: cognito.adminUserPool.userPoolId,
      adminUserPoolClientId: cognito.adminUserPoolClient.userPoolClientId,
    };

    if (props.config.environment === 'prod') {
      // Only access userPoolClientSecret if we are in prod, where generateSecret is true
      // The UserPoolClient construct in cognito.ts sets generateSecret based on isProd.
      // So, these secrets should exist and be resolvable in prod.
      cognitoSecretJson.clientUserPoolClientSecret = cognito.clientUserPoolClient.userPoolClientSecret!.unsafeUnwrap();
      cognitoSecretJson.adminUserPoolClientSecret = cognito.adminUserPoolClient.userPoolClientSecret!.unsafeUnwrap();
    }

    const updateCognitoConfigSecret = new cdk.custom_resources.AwsCustomResource(this, 'UpdateCognitoConfigSecret', {
      onCreate: {
        service: 'SecretsManager',
        action: 'putSecretValue', 
        parameters: {
          SecretId: secrets.cognitoConfigSecret.secretName, 
          SecretString: JSON.stringify(cognitoSecretJson),
        },
        physicalResourceId: cdk.custom_resources.PhysicalResourceId.of(`UpdateCognitoConfigSecret-${cognito.clientUserPool.userPoolId}`),
      },
      onUpdate: {
        service: 'SecretsManager',
        action: 'putSecretValue',
        parameters: {
          SecretId: secrets.cognitoConfigSecret.secretName, 
          SecretString: JSON.stringify(cognitoSecretJson),
        },
        physicalResourceId: cdk.custom_resources.PhysicalResourceId.of(`UpdateCognitoConfigSecret-${cognito.clientUserPool.userPoolId}`),
      },
      policy: cdk.custom_resources.AwsCustomResourcePolicy.fromStatements([
        new iamcdk.PolicyStatement({
          actions: ['secretsmanager:PutSecretValue', 'secretsmanager:DescribeSecret'],
          resources: [secrets.cognitoConfigSecret.secretArn],
          effect: iamcdk.Effect.ALLOW, 
        }),
      ]),
    });
    updateCognitoConfigSecret.node.addDependency(cognito); // Depends on cognito resources
    updateCognitoConfigSecret.node.addDependency(secrets.cognitoConfigSecret); // Depends on the placeholder secret object

    const monitoring = new MonitoringConstruct(this, 'Monitoring', {
      environment: props.config.environment,
      config: props.config,
      ecsCluster: ecsService.cluster,
      alarmTopic,
    });

    const uploadsBucket = new cdk.aws_s3.Bucket(this, 'UploadsBucket', {
      bucketName: `finefinds-${props.config.environment}-uploads`,
      versioned: props.config.s3.versioned,
      encryption: cdk.aws_s3.BucketEncryption.S3_MANAGED,
      blockPublicAccess: cdk.aws_s3.BlockPublicAccess.BLOCK_ALL,
      removalPolicy: props.config.environment === 'prod' 
        ? cdk.RemovalPolicy.RETAIN 
        : cdk.RemovalPolicy.DESTROY,
    });

    const cloudfront = new CloudFrontConstruct(this, 'CloudFront', {
      environment: props.config.environment,
      config: props.config,
      loadBalancer: ecsService.loadBalancer,
      uploadsBucket: uploadsBucket,
    });

    new cdk.CfnOutput(this, 'CloudFrontDomainName', {
      value: cloudfront.distribution.distributionDomainName,
      description: 'CloudFront distribution domain name for Dreamhost DNS configuration',
      exportName: `finefinds-${props.config.environment}-cf-domain-name`,
    });

    new cdk.CfnOutput(this, 'LoadBalancerDnsName', {
      value: ecsService.loadBalancer.loadBalancerDnsName,
      description: 'Load Balancer DNS name for Dreamhost DNS configuration',
      exportName: `finefinds-${props.config.environment}-lb-dns-name`,
    });

    if (props.config.environment === 'prod') {
      new BackupConstruct(this, 'Backup', {
        environment: props.config.environment,
        config: props.config,
      });
      new WafConstruct(this, 'Waf', {
        environment: props.config.environment,
        config: props.config,
        loadBalancer: ecsService.loadBalancer,
      });
    }

    if (props.config.environment === 'prod' || props.config.environment === 'uat') {
      new DynamoDBConstruct(this, 'DynamoDB', {
        environment: props.config.environment,
        config: props.config,
        kmsKey: kms.key,
      });
    }

    new AmplifyConstruct(this, 'Amplify', {
      environment: props.config.environment,
      config: props.config,
    });

    if (['dev', 'sandbox', 'qa', 'uat'].includes(props.config.environment)) {
      const bastion = new BastionConstruct(this, 'Bastion', {
        environment: props.config.environment,
        config: props.config,
        vpc: vpc.vpc,
      });
      if (props.config.environment === 'prod' && rds.cluster) {
        rds.cluster.connections.allowDefaultPortFrom(bastion.securityGroup, 'Allow access from bastion host');
      } else if (rds.instance) {
        rds.instance.connections.allowDefaultPortFrom(bastion.securityGroup, 'Allow access from bastion host');
      }
    }

    cdk.Tags.of(this).add('Environment', props.config.environment);
    cdk.Tags.of(this).add('Project', 'finefinds');
    cdk.Tags.of(this).add('ManagedBy', 'CDK');
    
    if (['dev', 'sandbox', 'qa'].includes(props.config.environment)) {
      new AutoShutdownConstruct(this, 'AutoShutdown', {
        environment: props.config.environment,
        config: props.config,
        cluster: ecsService.cluster,
        service: ecsService.service,
      });
    }
  }
}