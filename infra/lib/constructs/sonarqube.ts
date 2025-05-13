import * as cdk from 'aws-cdk-lib';
import * as ecs from 'aws-cdk-lib/aws-ecs';
import * as ec2 from 'aws-cdk-lib/aws-ec2';
import * as rds from 'aws-cdk-lib/aws-rds';
import * as secretsmanager from 'aws-cdk-lib/aws-secretsmanager';
import * as iam from 'aws-cdk-lib/aws-iam';
import * as elbv2 from 'aws-cdk-lib/aws-elasticloadbalancingv2';
import * as ecr from 'aws-cdk-lib/aws-ecr';
import { Construct } from 'constructs';
import { BaseConfig } from '../../env/base-config';

export interface SonarQubeConstructProps {
  environment: string;
  config: BaseConfig;
  vpc: ec2.Vpc;
  kmsKey: cdk.aws_kms.Key;
  taskRole?: iam.IRole;
  executionRole?: iam.IRole;
}

export class SonarQubeConstruct extends Construct {
  public readonly service?: ecs.FargateService;
  public readonly database?: rds.DatabaseInstance;
  public readonly loadBalancer?: elbv2.ApplicationLoadBalancer;

  constructor(scope: Construct, id: string, props: SonarQubeConstructProps) {
    super(scope, id);

    // Create security group for SonarQube
    const securityGroup = new ec2.SecurityGroup(this, 'SonarQubeSecurityGroup', {
      vpc: props.vpc,
      description: 'Security group for SonarQube',
      allowAllOutbound: true,
    });

    // Allow inbound SonarQube access
    securityGroup.addIngressRule(
      ec2.Peer.ipv4(props.vpc.vpcCidrBlock),
      ec2.Port.tcp(9000),
      'Allow SonarQube access from within VPC'
    );

    // Create database for SonarQube - using a larger instance since this is a shared resource
    this.database = new rds.DatabaseInstance(this, 'Database', {
      engine: rds.DatabaseInstanceEngine.postgres({
        version: rds.PostgresEngineVersion.VER_13,
      }),
      // Use a more powerful instance since this will serve multiple projects/repos
      instanceType: ec2.InstanceType.of(
        ec2.InstanceClass.T3,
        ec2.InstanceSize.SMALL
      ),
      vpc: props.vpc,
      vpcSubnets: {
        subnetType: ec2.SubnetType.PRIVATE_WITH_EGRESS
      },
      securityGroups: [securityGroup],
      // Increase storage for the shared instance
      allocatedStorage: 30,
      maxAllocatedStorage: 100,
      backupRetention: cdk.Duration.days(7),
      // Always retain the database to prevent data loss
      removalPolicy: cdk.RemovalPolicy.RETAIN,
      databaseName: 'sonarqube',
      credentials: rds.Credentials.fromGeneratedSecret('sonarqube'),
    });

    // Create ECS task definition with increased resources for the shared instance
    const taskDefinition = new ecs.FargateTaskDefinition(this, 'TaskDef', {
      memoryLimitMiB: 8192, // Increased from 4096
      cpu: 2048, // Increased from 1024
      taskRole: props.taskRole,
      executionRole: props.executionRole,
    });

    // Add container to task definition
    const container = taskDefinition.addContainer('SonarQubeContainer', {
      image: ecs.ContainerImage.fromEcrRepository(
        ecr.Repository.fromRepositoryAttributes(this, 'ECRRepo', {
          repositoryArn: 'arn:aws:ecr:us-east-1:891076991993:repository/finefinds-base/sonarqube',
          repositoryName: 'finefinds-base/sonarqube',
        })
      ),
      logging: ecs.LogDrivers.awsLogs({
        streamPrefix: 'sonarqube',
      }),
      environment: {
        SONAR_JDBC_URL: `jdbc:postgresql://${this.database.instanceEndpoint.hostname}:5432/sonarqube`,
        SONAR_JDBC_USERNAME: 'sonarqube',
        SONAR_ES_BOOTSTRAP_CHECKS_DISABLE: 'true', 
        // Additional configuration for better performance
        SONAR_WEB_JAVAADDITIONALOPTS: '-Xmx2G -Xms2G',
        SONAR_CE_JAVAADDITIONALOPTS: '-Xmx4G -Xms2G',
        SONAR_SEARCH_JAVAADDITIONALOPTS: '-Xmx2G -Xms2G',
      },
      secrets: {
        SONAR_JDBC_PASSWORD: ecs.Secret.fromSecretsManager(
          this.database.secret!,
          'password'
        ),
      },
      portMappings: [
        {
          containerPort: 9000,
          protocol: ecs.Protocol.TCP,
        },
      ],
    });

    // Create ECS cluster
    const cluster = new ecs.Cluster(this, 'Cluster', {
      vpc: props.vpc,
      clusterName: `sonarqube-shared`, // Changed to indicate this is a shared instance
      containerInsights: true, // Enable container insights for better monitoring
    });

    // Create ECS service
    this.service = new ecs.FargateService(this, 'Service', {
      cluster: cluster,
      taskDefinition,
      desiredCount: 1,
      securityGroups: [securityGroup],
      vpcSubnets: {
        subnetType: ec2.SubnetType.PRIVATE_WITH_EGRESS
      },
      assignPublicIp: false,
      // Enable ECS service auto scaling based on CPU and memory
      capacityProviderStrategies: [
        {
          capacityProvider: 'FARGATE',
          weight: 1,
        },
      ],
    });

    // Create Application Load Balancer for SonarQube
    this.loadBalancer = new elbv2.ApplicationLoadBalancer(this, 'LoadBalancer', {
      vpc: props.vpc,
      internetFacing: true,
      securityGroup: securityGroup,
      vpcSubnets: {
        subnetType: ec2.SubnetType.PUBLIC,
      },
    });

    // Create target group for SonarQube
    const targetGroup = new elbv2.ApplicationTargetGroup(this, 'TargetGroup', {
      vpc: props.vpc,
      port: 9000,
      protocol: elbv2.ApplicationProtocol.HTTP,
      targetType: elbv2.TargetType.IP,
      healthCheck: {
        path: '/',
        interval: cdk.Duration.seconds(60),
        timeout: cdk.Duration.seconds(5),
        healthyHttpCodes: '200',
      },
      // Add stickiness for better user experience
      stickinessCookieDuration: cdk.Duration.days(1),
      stickinessCookieName: 'SONAR_SESSIONID',
    });

    // Add listener to load balancer
    const listener = this.loadBalancer.addListener('Listener', {
      port: 80,
      defaultTargetGroups: [targetGroup],
    });

    // Connect SonarQube service to target group
    this.service.attachToApplicationTargetGroup(targetGroup);

    // Output SonarQube URL
    new cdk.CfnOutput(this, 'SonarQubeUrl', {
      value: `http://${this.loadBalancer.loadBalancerDnsName}`,
      description: 'SonarQube URL',
      exportName: 'finefinds-shared-sonarqube-url',
    });
  }
} 