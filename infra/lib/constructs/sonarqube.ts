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
import * as logs from 'aws-cdk-lib/aws-logs';

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

    // Create a dedicated security group for the database
    const dbSecurityGroup = new ec2.SecurityGroup(this, 'DatabaseSecurityGroup', {
      vpc: props.vpc,
      description: 'Security group for SonarQube database',
      allowAllOutbound: false,
    });

    // Allow inbound SonarQube access
    securityGroup.addIngressRule(
      ec2.Peer.ipv4(props.vpc.vpcCidrBlock),
      ec2.Port.tcp(9000),
      'Allow SonarQube access from within VPC'
    );

    // Allow PostgreSQL connections from SonarQube security group to DB security group
    dbSecurityGroup.addIngressRule(
      securityGroup,
      ec2.Port.tcp(5432),
      'Allow PostgreSQL access from SonarQube containers'
    );

    // Allow outbound PostgreSQL connections from SonarQube to DB
    securityGroup.addEgressRule(
      dbSecurityGroup,
      ec2.Port.tcp(5432),
      'Allow outbound PostgreSQL connections to database'
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
      securityGroups: [dbSecurityGroup],
      // Increase storage for the shared instance
      allocatedStorage: 30,
      maxAllocatedStorage: 100,
      backupRetention: cdk.Duration.days(7),
      // Always retain the database to prevent data loss
      removalPolicy: cdk.RemovalPolicy.RETAIN,
      databaseName: 'sonarqube',
      credentials: rds.Credentials.fromGeneratedSecret('sonarqube'),
      // Set longer connection timeout for PostgreSQL
      parameterGroup: new rds.ParameterGroup(this, 'SonarQubeDBParamGroup', {
        engine: rds.DatabaseInstanceEngine.postgres({
          version: rds.PostgresEngineVersion.VER_13
        }),
        parameters: {
          'tcp_keepalives_idle': '60',
          'tcp_keepalives_interval': '10',
          'tcp_keepalives_count': '10',
          'statement_timeout': '600000',  // 10 minutes in milliseconds
          'idle_in_transaction_session_timeout': '3600000',  // 1 hour in milliseconds
        }
      })
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
        SONAR_JDBC_URL: `jdbc:postgresql://${this.database.instanceEndpoint.hostname}:5432/sonarqube?socketTimeout=60&connectTimeout=30&loginTimeout=30&tcpKeepAlive=true`,
        SONARQUBE_JDBC_URL: `jdbc:postgresql://${this.database.instanceEndpoint.hostname}:5432/sonarqube?socketTimeout=60&connectTimeout=30&loginTimeout=30&tcpKeepAlive=true`,
        SONAR_JDBC_USERNAME: 'sonarqube',
        SONARQUBE_JDBC_USERNAME: 'sonarqube',
        SONAR_ES_BOOTSTRAP_CHECKS_DISABLE: 'true', 
        // Additional configuration for better performance
        SONAR_WEB_JAVAADDITIONALOPTS: '-Xmx2G -Xms2G',
        SONAR_CE_JAVAADDITIONALOPTS: '-Xmx4G -Xms2G',
        SONAR_SEARCH_JAVAADDITIONALOPTS: '-Xmx2G -Xms2G',
        // Database connection pool settings
        SONAR_JDBC_MAXACTIVE: '20',
        SONAR_JDBC_MINIDLE: '5',
        SONAR_JDBC_MAXIDLE: '10',
        SONAR_JDBC_MAXWAIT: '30000',
        // Set startup timeout
        SONAR_WEB_STARTUPGRACEPERIOD: '300',
      },
      secrets: {
        SONAR_JDBC_PASSWORD: ecs.Secret.fromSecretsManager(
          this.database.secret!,
          'password'
        ),
        SONARQUBE_JDBC_PASSWORD: ecs.Secret.fromSecretsManager(
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
      healthCheck: {
        command: ["CMD-SHELL", "wget -q --spider http://localhost:9000/api/system/status || exit 1"],
        interval: cdk.Duration.seconds(30),
        timeout: cdk.Duration.seconds(10),
        retries: 3,
        startPeriod: cdk.Duration.seconds(180),
      },
      // Set essential to true to ensure ECS restarts the container if it fails
      essential: true,
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
      assignPublicIp: true, // This is required for isolated subnets without NAT gateway
      healthCheckGracePeriod: cdk.Duration.seconds(300), // Increase grace period
      // Enable ECS service auto scaling based on CPU and memory
      capacityProviderStrategies: [
        {
          capacityProvider: 'FARGATE',
          weight: 1,
        },
      ],
    });

    // Explicitly add dependency to ensure database is created before the service
    this.service.node.addDependency(this.database);
    
    // Create log group for SonarQube service
    const serviceLogGroup = new logs.LogGroup(this, 'ServiceLogGroup', {
      logGroupName: `finefinds-shared-sonarqube-service-logs`,
      retention: logs.RetentionDays.ONE_MONTH,
      removalPolicy: cdk.RemovalPolicy.RETAIN,
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
        path: '/api/system/status',
        interval: cdk.Duration.seconds(30),
        timeout: cdk.Duration.seconds(10),
        healthyThresholdCount: 2,
        unhealthyThresholdCount: 3,
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