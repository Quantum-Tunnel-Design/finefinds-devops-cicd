import * as cdk from 'aws-cdk-lib';
import * as ecs from 'aws-cdk-lib/aws-ecs';
import * as ec2 from 'aws-cdk-lib/aws-ec2';
import * as elbv2 from 'aws-cdk-lib/aws-elasticloadbalancingv2';
import * as logs from 'aws-cdk-lib/aws-logs';
import * as iam from 'aws-cdk-lib/aws-iam';
import * as ecr from 'aws-cdk-lib/aws-ecr';
import * as servicediscovery from 'aws-cdk-lib/aws-servicediscovery';
import { Construct } from 'constructs';
import { BaseConfig } from '../../env/base-config';

export interface EcsConstructProps {
  environment: string;
  config: BaseConfig;
  vpc: ec2.Vpc;
  taskRole?: iam.IRole;
  executionRole?: iam.IRole;
  secrets?: { [key: string]: ecs.Secret };
}

export class EcsConstruct extends Construct {
  public readonly cluster: ecs.Cluster;
  public readonly service: ecs.FargateService;
  public readonly loadBalancer: elbv2.ApplicationLoadBalancer;

  constructor(scope: Construct, id: string, props: EcsConstructProps) {
    super(scope, id);

    // Create ECS cluster
    this.cluster = new ecs.Cluster(this, 'Cluster', {
      vpc: props.vpc,
      clusterName: `finefinds-${props.environment}-cluster`,
      containerInsights: props.environment === 'prod',
    });

    // Explicitly create the PrivateDnsNamespace for service discovery
    const cloudMapNamespace = new servicediscovery.PrivateDnsNamespace(this, 'ServiceDiscoveryNamespace', {
        name: `finefinds.${props.environment}.local`,
        vpc: props.vpc,
        description: `Private DNS namespace for ${props.environment} environment of FineFinds`,
    });

    // Create task definition
    const taskDefinition = new ecs.FargateTaskDefinition(this, 'TaskDef', {
      memoryLimitMiB: props.environment === 'prod' 
        ? props.config.ecs.memoryLimitMiB 
        : 512,
      cpu: props.environment === 'prod' 
        ? props.config.ecs.cpu 
        : 256,
      taskRole: props.taskRole,
      executionRole: props.executionRole,
    });

    // Reference to the placeholder ECR image that the service will initially start with.
    // The actual application image will be deployed later by a separate CI/CD pipeline for the backend.
    const placeholderEcrRepo = ecr.Repository.fromRepositoryAttributes(this, 'PlaceholderEcrRepoForInitialService', { // Unique ID
      repositoryArn: 'arn:aws:ecr:us-east-1:891076991993:repository/finefinds-base/node-20-alpha',
      repositoryName: 'finefinds-base/node-20-alpha',
    });

    // Add a resource policy to this ECR repository to allow the ECS Execution Role to pull images
    // This is a good practice in addition to the IAM role's identity-based policy.
    placeholderEcrRepo.addToResourcePolicy(new iam.PolicyStatement({
      sid: 'AllowEcsExecutionRolePull',
      effect: iam.Effect.ALLOW,
      principals: [props.executionRole!], // Use the executionRole passed in props
      actions: [
        'ecr:BatchCheckLayerAvailability',
        'ecr:GetDownloadUrlForLayer',
        'ecr:BatchGetImage',
      ],
    }));

    const container = taskDefinition.addContainer('AppContainer', {
      image: ecs.ContainerImage.fromEcrRepository(
        placeholderEcrRepo, // Use the placeholder ECR repository
        'latest'
      ),
      logging: ecs.LogDrivers.awsLogs({
        streamPrefix: 'finefinds',
        logGroup: new logs.LogGroup(this, 'AppLogGroup', {
          logGroupName: `/finefinds/${props.environment}/app`,
          retention: props.environment === 'prod' 
            ? logs.RetentionDays.ONE_MONTH 
            : logs.RetentionDays.ONE_DAY,
          removalPolicy: props.environment === 'prod' 
            ? cdk.RemovalPolicy.RETAIN 
            : cdk.RemovalPolicy.DESTROY,
        }),
      }),
      environment: {
        NODE_ENV: props.environment,
        PORT: props.config.ecs.containerPort.toString(),
      },
      secrets: {
        ...props.secrets,
        // Add secrets for database and Redis connection
        DATABASE_URL: ecs.Secret.fromSecretsManager(
          cdk.aws_secretsmanager.Secret.fromSecretNameV2(
            this,
            'DbConnectionSecret',
            `finefinds-${props.environment}-rds-connection`
          ),
          'connectionString'
        ),
        REDIS_URL: ecs.Secret.fromSecretsManager(
          cdk.aws_secretsmanager.Secret.fromSecretNameV2(
            this,
            'RedisConnectionSecret',
            `finefinds-${props.environment}-redis-connection`
          )
        ),
        COGNITO_CLIENT_USER_POOL_ID: ecs.Secret.fromSecretsManager(
          cdk.aws_secretsmanager.Secret.fromSecretNameV2(
            this,
            'CognitoConfigSecretCognitoClientUserPoolId',
            `finefinds-${props.environment}-cognito-config`
          ),
          'clientUserPoolId'
        ),
        COGNITO_CLIENT_CLIENT_ID: ecs.Secret.fromSecretsManager(
          cdk.aws_secretsmanager.Secret.fromSecretNameV2(
            this,
            'CognitoConfigSecretCognitoAppClientUserPoolId',
            `finefinds-${props.environment}-cognito-config`
          ),
          'clientUserPoolClientId'
        ),
        COGNITO_ADMIN_USER_POOL_ID: ecs.Secret.fromSecretsManager(
          cdk.aws_secretsmanager.Secret.fromSecretNameV2(
            this,
            'CognitoConfigSecretCognitoAdminserPoolId',
            `finefinds-${props.environment}-cognito-config`
          ),
          'adminUserPoolId'
        ),
        COGNITO_ADMIN_CLIENT_ID: ecs.Secret.fromSecretsManager(
          cdk.aws_secretsmanager.Secret.fromSecretNameV2(
            this,
            'CognitoConfigSecretCognitoAdminClientUserPoolId',
            `finefinds-${props.environment}-cognito-config`
          ),
          'adminUserPoolClientId'
        ),
      },
      portMappings: [
        {
          containerPort: props.config.ecs.containerPort,
          protocol: ecs.Protocol.TCP,
        },
      ],
      healthCheck: {
        command: ['CMD-SHELL', 'curl -f http://localhost:3000/health || exit 1'],
        interval: cdk.Duration.seconds(60),
        timeout: cdk.Duration.seconds(30),
        retries: 3,
        startPeriod: cdk.Duration.seconds(60),
      },
    });

    // Create security group for the service
    const securityGroup = new ec2.SecurityGroup(this, 'ServiceSecurityGroup', {
      vpc: props.vpc,
      description: 'Security group for FineFinds service',
      allowAllOutbound: true,
    });

    // Allow inbound access from the load balancer
    securityGroup.addIngressRule(
      ec2.Peer.ipv4(props.vpc.vpcCidrBlock),
      ec2.Port.tcp(props.config.ecs.containerPort),
      'Allow inbound access from within VPC'
    );

    // Create load balancer
    this.loadBalancer = new elbv2.ApplicationLoadBalancer(this, 'LoadBalancer', {
      vpc: props.vpc,
      internetFacing: true,
      securityGroup: securityGroup,
      vpcSubnets: {
        subnetType: ec2.SubnetType.PUBLIC,
      },
    });

    // Create target group
    const targetGroup = new elbv2.ApplicationTargetGroup(this, 'TargetGroup', {
      vpc: props.vpc,
      port: props.config.ecs.containerPort,
      protocol: elbv2.ApplicationProtocol.HTTP,
      targetType: elbv2.TargetType.IP,
      healthCheck: {
        path: '/health',
        interval: cdk.Duration.seconds(60),
        timeout: cdk.Duration.seconds(30),
        healthyThresholdCount: 2,
        unhealthyThresholdCount: 4,
        healthyHttpCodes: '200',
      },
    });

    // Add listener to load balancer
    const listener = this.loadBalancer.addListener('Listener', {
      port: 80,
      defaultTargetGroups: [targetGroup],
    });

    // Add HTTPS listener if in production
    if (props.environment === 'prod') {
      // Create a self-signed certificate if no domain is available
      const certificate = new cdk.aws_certificatemanager.Certificate(this, 'SelfSignedCert', {
        domainName: this.loadBalancer.loadBalancerDnsName,
      });
      
      this.loadBalancer.addListener('HttpsListener', {
        port: 443,
        defaultTargetGroups: [targetGroup],
        certificates: [certificate],
      });
    }

    // Create Fargate service
    this.service = new ecs.FargateService(this, 'Service', {
      cluster: this.cluster,
      taskDefinition: taskDefinition,
      desiredCount: props.config.ecs.desiredCount,
      maxHealthyPercent: 200,
      minHealthyPercent: 50,
      securityGroups: [securityGroup],
      vpcSubnets: {
        subnetType: ec2.SubnetType.PRIVATE_WITH_EGRESS,
      },
      assignPublicIp: false,
      serviceName: `finefinds-${props.environment}-service`,
      cloudMapOptions: {
        name: 'app',
        dnsRecordType: servicediscovery.DnsRecordType.A,
        dnsTtl: cdk.Duration.seconds(60),
        cloudMapNamespace: cloudMapNamespace,
      }
    });

    // Add service to target group
    this.service.attachToApplicationTargetGroup(targetGroup);

    // Create auto scaling
    const scaling = this.service.autoScaleTaskCount({
      maxCapacity: props.environment === 'prod' 
        ? props.config.ecs.maxCapacity 
        : Math.min(props.config.ecs.maxCapacity, 2),
      minCapacity: props.environment === 'prod'
        ? props.config.ecs.minCapacity
        : 1,
    });

    // Add scaling policies - simplified for non-prod
    if (props.environment === 'prod') {
      // More aggressive scaling for production
      scaling.scaleOnCpuUtilization('CpuScaling', {
        targetUtilizationPercent: 70,
        scaleInCooldown: cdk.Duration.seconds(60),
        scaleOutCooldown: cdk.Duration.seconds(60),
      });

      scaling.scaleOnMemoryUtilization('MemoryScaling', {
        targetUtilizationPercent: 70,
        scaleInCooldown: cdk.Duration.seconds(60),
        scaleOutCooldown: cdk.Duration.seconds(60),
      });
    } else {
      // Simpler, less aggressive scaling for non-prod
      scaling.scaleOnCpuUtilization('CpuScaling', {
        targetUtilizationPercent: 80,
        scaleInCooldown: cdk.Duration.seconds(300),
        scaleOutCooldown: cdk.Duration.seconds(300),
      });
    }

    // Add CloudWatch alarms for monitoring
    const cpuAlarm = new cdk.aws_cloudwatch.Alarm(this, 'CpuUtilizationAlarm', {
      metric: this.service.metricCpuUtilization(),
      threshold: 80,
      evaluationPeriods: 3,
      datapointsToAlarm: 2,
      alarmDescription: 'Alarm if CPU utilization exceeds 80%',
    });

    const memoryAlarm = new cdk.aws_cloudwatch.Alarm(this, 'MemoryUtilizationAlarm', {
      metric: this.service.metricMemoryUtilization(),
      threshold: 80,
      evaluationPeriods: 3,
      datapointsToAlarm: 2,
      alarmDescription: 'Alarm if memory utilization exceeds 80%',
    });

    // Output load balancer DNS
    new cdk.CfnOutput(this, 'LoadBalancerDns', {
      value: this.loadBalancer.loadBalancerDnsName,
      description: 'Load Balancer DNS',
      exportName: `finefinds-${props.environment}-lb-dns`,
    });
  }
} 