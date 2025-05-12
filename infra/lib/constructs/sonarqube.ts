import * as cdk from 'aws-cdk-lib';
import * as ecs from 'aws-cdk-lib/aws-ecs';
import * as ec2 from 'aws-cdk-lib/aws-ec2';
import * as rds from 'aws-cdk-lib/aws-rds';
import * as secretsmanager from 'aws-cdk-lib/aws-secretsmanager';
import * as iam from 'aws-cdk-lib/aws-iam';
import * as elbv2 from 'aws-cdk-lib/aws-elasticloadbalancingv2';
import { Construct } from 'constructs';
import { BaseConfig } from '../../env/base-config';

export interface SonarQubeConstructProps {
  environment: string;
  config: BaseConfig;
  vpc: ec2.Vpc;
  kmsKey: cdk.aws_kms.Key;
}

export class SonarQubeConstruct extends Construct {
  public readonly service?: ecs.FargateService;
  public readonly database?: rds.DatabaseInstance;

  constructor(scope: Construct, id: string, props: SonarQubeConstructProps) {
    super(scope, id);

    // Only create SonarQube in production or a dedicated CI/CD environment
    if (props.environment === 'prod' || props.environment === 'ci') {
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

      // Create database for SonarQube
      this.database = new rds.DatabaseInstance(this, 'Database', {
        engine: rds.DatabaseInstanceEngine.postgres({
          version: rds.PostgresEngineVersion.VER_13,
        }),
        instanceType: ec2.InstanceType.of(
          ec2.InstanceClass.T3,
          ec2.InstanceSize.MICRO
        ),
        vpc: props.vpc,
        vpcSubnets: {
          subnetType: props.environment === 'prod' 
            ? ec2.SubnetType.PRIVATE_WITH_EGRESS 
            : ec2.SubnetType.PRIVATE_ISOLATED,
        },
        securityGroups: [securityGroup],
        allocatedStorage: 20,
        maxAllocatedStorage: 100,
        backupRetention: cdk.Duration.days(7),
        removalPolicy: props.environment === 'prod' 
          ? cdk.RemovalPolicy.RETAIN 
          : cdk.RemovalPolicy.DESTROY,
        databaseName: 'sonarqube',
        credentials: rds.Credentials.fromGeneratedSecret('sonarqube'),
      });

      // Create ECS task definition
      const taskDefinition = new ecs.FargateTaskDefinition(this, 'TaskDef', {
        memoryLimitMiB: 4096,
        cpu: 1024,
      });

      // Add container to task definition
      const container = taskDefinition.addContainer('SonarQubeContainer', {
        image: ecs.ContainerImage.fromRegistry('sonarqube:community'),
        logging: ecs.LogDrivers.awsLogs({
          streamPrefix: 'sonarqube',
        }),
        environment: {
          SONAR_JDBC_URL: `jdbc:postgresql://${this.database.instanceEndpoint.hostname}:5432/sonarqube`,
          SONAR_JDBC_USERNAME: 'sonarqube',
          SONAR_ES_BOOTSTRAP_CHECKS_DISABLE: 'true', // disables production check for dev
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

      // Create ECS service
      this.service = new ecs.FargateService(this, 'Service', {
        cluster: new ecs.Cluster(this, 'Cluster', {
          vpc: props.vpc,
          clusterName: `sonarqube-${props.environment}`,
        }),
        taskDefinition,
        desiredCount: 1,
        securityGroups: [securityGroup],
        vpcSubnets: {
          subnetType: props.environment === 'prod' 
            ? ec2.SubnetType.PRIVATE_WITH_EGRESS 
            : ec2.SubnetType.PRIVATE_ISOLATED,
        },
        assignPublicIp: false,
      });

      // Create Application Load Balancer for SonarQube
      const lb = new elbv2.ApplicationLoadBalancer(this, 'LoadBalancer', {
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
      });

      // Add listener to load balancer
      const listener = lb.addListener('Listener', {
        port: 80,
        defaultTargetGroups: [targetGroup],
      });

      // Connect SonarQube service to target group
      this.service.attachToApplicationTargetGroup(targetGroup);

      // Output SonarQube URL
      new cdk.CfnOutput(this, 'SonarQubeUrl', {
        value: `http://${lb.loadBalancerDnsName}`,
        description: 'SonarQube URL',
        exportName: `finefinds-${props.environment}-sonarqube-url`,
      });
    } else {
      // For non-prod environments, output a message about the centralized SonarQube instance
      console.log('SonarQube is only deployed in production or CI/CD environments to reduce resource usage. Non-production environments should use the centralized SonarQube instance.');
    }
  }
} 