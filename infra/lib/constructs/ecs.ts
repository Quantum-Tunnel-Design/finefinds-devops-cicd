import * as cdk from 'aws-cdk-lib';
import * as ecs from 'aws-cdk-lib/aws-ecs';
import * as ec2 from 'aws-cdk-lib/aws-ec2';
import * as elbv2 from 'aws-cdk-lib/aws-elasticloadbalancingv2';
import * as logs from 'aws-cdk-lib/aws-logs';
import * as iam from 'aws-cdk-lib/aws-iam';
import { Construct } from 'constructs';
import { BaseConfig } from '../../env/base-config';

export interface EcsConstructProps {
  environment: string;
  config: BaseConfig;
  vpc: ec2.Vpc;
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
      containerInsights: true,
    });

    // Create task definition
    const taskDefinition = new ecs.FargateTaskDefinition(this, 'TaskDef', {
      memoryLimitMiB: props.config.ecs.memoryLimitMiB,
      cpu: props.config.ecs.cpu,
    });

    // Add container to task definition
    const container = taskDefinition.addContainer('AppContainer', {
      image: ecs.ContainerImage.fromRegistry('public.ecr.aws/docker/library/node:20-alpine'),
      logging: ecs.LogDrivers.awsLogs({
        streamPrefix: 'finefinds',
        logGroup: new logs.LogGroup(this, 'AppLogGroup', {
          logGroupName: `/finefinds/${props.environment}/app`,
          retention: props.environment === 'prod' 
            ? logs.RetentionDays.ONE_MONTH 
            : logs.RetentionDays.ONE_WEEK,
          removalPolicy: props.environment === 'prod' 
            ? cdk.RemovalPolicy.RETAIN 
            : cdk.RemovalPolicy.DESTROY,
        }),
      }),
      environment: {
        NODE_ENV: props.environment,
        PORT: props.config.ecs.containerPort.toString(),
      },
      portMappings: [
        {
          containerPort: props.config.ecs.containerPort,
          protocol: ecs.Protocol.TCP,
        },
      ],
    });

    // Create security group for the service
    const securityGroup = new ec2.SecurityGroup(this, 'ServiceSecurityGroup', {
      vpc: props.vpc,
      description: 'Security group for FineFinds service',
      allowAllOutbound: true,
    });

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
        interval: cdk.Duration.seconds(30),
        timeout: cdk.Duration.seconds(5),
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
      this.loadBalancer.addListener('HttpsListener', {
        port: 443,
        defaultTargetGroups: [targetGroup],
        certificates: [], // Add ACM certificate here
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
    });

    // Add service to target group
    this.service.attachToApplicationTargetGroup(targetGroup);

    // Create auto scaling
    const scaling = this.service.autoScaleTaskCount({
      maxCapacity: props.config.ecs.maxCapacity,
      minCapacity: props.config.ecs.desiredCount,
    });

    // Add scaling policies
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

    // Output load balancer DNS
    new cdk.CfnOutput(this, 'LoadBalancerDns', {
      value: this.loadBalancer.loadBalancerDnsName,
      description: 'Load Balancer DNS',
      exportName: `finefinds-${props.environment}-lb-dns`,
    });
  }
} 