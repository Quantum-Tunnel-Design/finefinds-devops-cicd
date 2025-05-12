import * as cdk from 'aws-cdk-lib';
import * as cloudwatch from 'aws-cdk-lib/aws-cloudwatch';
import * as cloudwatch_actions from 'aws-cdk-lib/aws-cloudwatch-actions';
import * as logs from 'aws-cdk-lib/aws-logs';
import * as sns from 'aws-cdk-lib/aws-sns';
import * as iam from 'aws-cdk-lib/aws-iam';
import * as ecs from 'aws-cdk-lib/aws-ecs';
import { Construct } from 'constructs';
import { BaseConfig } from '../../env/base-config';

export interface MonitoringConstructProps {
  environment: string;
  config: BaseConfig;
  ecsCluster: ecs.ICluster;
  alarmTopic: sns.ITopic;
}

export class MonitoringConstruct extends Construct {
  public readonly dashboard: cloudwatch.Dashboard;
  private readonly region: string;
  private readonly environment: string;

  constructor(scope: Construct, id: string, props: MonitoringConstructProps) {
    super(scope, id);

    // Get region from stack
    const stack = cdk.Stack.of(this);
    this.region = stack.region;
    this.environment = props.environment;

    // Create CloudWatch Dashboard
    this.dashboard = new cloudwatch.Dashboard(this, 'Dashboard', {
      dashboardName: `finefinds-${props.environment}-dashboard`,
    });

    // Create ECS Alarms
    this.createEcsAlarms(props);

    // Create X-Ray Configuration
    this.setupXRay(props);

    // Create Log Groups with Retention
    this.setupLogGroups(props);

    // Create Metric Filters
    this.createMetricFilters(props);

    // Create Dashboard Widgets
    this.createDashboardWidgets(props);
  }

  private createEcsAlarms(props: MonitoringConstructProps): void {
    // CPU Utilization Alarm
    const cpuAlarm = new cloudwatch.Alarm(this, 'CpuUtilizationAlarm', {
      metric: new cloudwatch.Metric({
        namespace: 'AWS/ECS',
        metricName: 'CPUUtilization',
        dimensionsMap: {
          ClusterName: props.ecsCluster.clusterName,
        },
        statistic: 'Average',
        period: cdk.Duration.minutes(1),
      }),
      threshold: 80,
      evaluationPeriods: 3,
      datapointsToAlarm: 2,
      alarmDescription: 'Alarm if CPU utilization exceeds 80%',
      comparisonOperator: cloudwatch.ComparisonOperator.GREATER_THAN_THRESHOLD,
      treatMissingData: cloudwatch.TreatMissingData.BREACHING,
    });

    // Memory Utilization Alarm
    const memoryAlarm = new cloudwatch.Alarm(this, 'MemoryUtilizationAlarm', {
      metric: new cloudwatch.Metric({
        namespace: 'AWS/ECS',
        metricName: 'MemoryUtilization',
        dimensionsMap: {
          ClusterName: props.ecsCluster.clusterName,
        },
        statistic: 'Average',
        period: cdk.Duration.minutes(1),
      }),
      threshold: 80,
      evaluationPeriods: 3,
      datapointsToAlarm: 2,
      alarmDescription: 'Alarm if memory utilization exceeds 80%',
      comparisonOperator: cloudwatch.ComparisonOperator.GREATER_THAN_THRESHOLD,
      treatMissingData: cloudwatch.TreatMissingData.BREACHING,
    });

    // Add alarms to SNS topic
    cpuAlarm.addAlarmAction(new cloudwatch_actions.SnsAction(props.alarmTopic));
    memoryAlarm.addAlarmAction(new cloudwatch_actions.SnsAction(props.alarmTopic));

    // Create OK actions
    cpuAlarm.addOkAction(new cloudwatch_actions.SnsAction(props.alarmTopic));
    memoryAlarm.addOkAction(new cloudwatch_actions.SnsAction(props.alarmTopic));
  }

  private setupXRay(props: MonitoringConstructProps): void {
    // Create X-Ray IAM policy
    const xrayPolicy = new iam.PolicyStatement({
      effect: iam.Effect.ALLOW,
      actions: [
        'xray:PutTraceSegments',
        'xray:PutTelemetryRecords',
        'xray:GetSamplingRules',
        'xray:GetSamplingTargets',
        'xray:GetSamplingStatisticSummaries',
      ],
      resources: ['*'],
    });

    // Add X-Ray policy to ECS task role
    if (props.ecsCluster.node.tryFindChild('TaskRole')) {
      const taskRole = props.ecsCluster.node.findChild('TaskRole') as iam.Role;
      taskRole.addToPolicy(xrayPolicy);
    }
  }

  private setupLogGroups(props: MonitoringConstructProps): void {
    // Create log groups with appropriate retention
    const retentionDays = props.environment === 'prod' ? 90 : 30;

    new logs.LogGroup(this, 'EcsLogGroup', {
      logGroupName: `/ecs/finefinds-${props.environment}`,
      retention: logs.RetentionDays.ONE_MONTH,
      removalPolicy: props.environment === 'prod' 
        ? cdk.RemovalPolicy.RETAIN 
        : cdk.RemovalPolicy.DESTROY,
    });

    new logs.LogGroup(this, 'ApplicationLogGroup', {
      logGroupName: `/finefinds/${props.environment}/application`,
      retention: logs.RetentionDays.ONE_MONTH,
      removalPolicy: props.environment === 'prod' 
        ? cdk.RemovalPolicy.RETAIN 
        : cdk.RemovalPolicy.DESTROY,
    });
  }

  private createMetricFilters(props: MonitoringConstructProps): void {
    // Create metric filter for error logs
    new logs.MetricFilter(this, 'ErrorMetricFilter', {
      logGroup: logs.LogGroup.fromLogGroupName(
        this,
        'ApplicationLogGroup',
        `/finefinds/${props.environment}/application`
      ),
      metricNamespace: `FineFinds/${props.environment}`,
      metricName: 'ErrorCount',
      filterPattern: logs.FilterPattern.literal('ERROR'),
      metricValue: '1',
    });

    // Create metric filter for warning logs
    new logs.MetricFilter(this, 'WarningMetricFilter', {
      logGroup: logs.LogGroup.fromLogGroupName(
        this,
        'ApplicationLogGroup',
        `/finefinds/${props.environment}/application`
      ),
      metricNamespace: `FineFinds/${props.environment}`,
      metricName: 'WarningCount',
      filterPattern: logs.FilterPattern.literal('WARN'),
      metricValue: '1',
    });
  }

  private createDashboardWidgets(props: MonitoringConstructProps): void {
    // Add ECS CPU Utilization widget
    this.dashboard.addWidgets(
      new cloudwatch.GraphWidget({
        title: 'ECS CPU Utilization',
        left: [
          new cloudwatch.Metric({
            namespace: 'AWS/ECS',
            metricName: 'CPUUtilization',
            dimensionsMap: {
              ClusterName: props.ecsCluster.clusterName,
            },
            statistic: 'Average',
            period: cdk.Duration.minutes(1),
          }),
        ],
        right: [
          new cloudwatch.Metric({
            namespace: 'AWS/ECS',
            metricName: 'MemoryUtilization',
            dimensionsMap: {
              ClusterName: props.ecsCluster.clusterName,
            },
            statistic: 'Average',
            period: cdk.Duration.minutes(1),
          }),
        ],
        width: 12,
      })
    );

    // Add ECS Memory Utilization widget
    this.dashboard.addWidgets(
      new cloudwatch.GraphWidget({
        title: 'ECS Memory Utilization',
        left: [
          new cloudwatch.Metric({
            namespace: 'AWS/ECS',
            metricName: 'MemoryUtilization',
            dimensionsMap: {
              ClusterName: props.ecsCluster.clusterName,
            },
            statistic: 'Average',
            period: cdk.Duration.minutes(1),
          }),
        ],
        width: 12,
      })
    );

    // Add Error and Warning Count widget
    this.dashboard.addWidgets(
      new cloudwatch.GraphWidget({
        title: 'Application Errors and Warnings',
        left: [
          new cloudwatch.Metric({
            namespace: `FineFinds/${props.environment}`,
            metricName: 'ErrorCount',
            statistic: 'Sum',
            period: cdk.Duration.minutes(1),
          }),
          new cloudwatch.Metric({
            namespace: `FineFinds/${props.environment}`,
            metricName: 'WarningCount',
            statistic: 'Sum',
            period: cdk.Duration.minutes(1),
          }),
        ],
        width: 12,
      })
    );

    // Add Request Count and Latency widget
    this.dashboard.addWidgets(
      new cloudwatch.GraphWidget({
        title: 'Request Count and Latency',
        left: [
          new cloudwatch.Metric({
            namespace: 'AWS/ApplicationELB',
            metricName: 'RequestCount',
            dimensionsMap: {
              LoadBalancer: `finefinds-${props.environment}-alb`,
            },
            statistic: 'Sum',
            period: cdk.Duration.minutes(1),
          }),
        ],
        right: [
          new cloudwatch.Metric({
            namespace: 'AWS/ApplicationELB',
            metricName: 'TargetResponseTime',
            dimensionsMap: {
              LoadBalancer: `finefinds-${props.environment}-alb`,
            },
            statistic: 'Average',
            period: cdk.Duration.minutes(1),
          }),
        ],
        width: 12,
      })
    );
  }

  public get dashboardUrl(): string {
    return `https://${this.region}.console.aws.amazon.com/cloudwatch/home?region=${this.region}#dashboards:name=finefinds-${this.environment}-dashboard`;
  }
} 