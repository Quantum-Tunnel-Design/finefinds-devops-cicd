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

    // Setup log groups
    this.setupLogGroups(props);

    // Create dashboard (only in production)
    if (props.environment === 'prod') {
      this.dashboard = new cloudwatch.Dashboard(this, 'Dashboard', {
        dashboardName: `finefinds-${props.environment}-dashboard`,
      });

      // Add widgets to dashboard
      this.setupDashboardWidgets(props);

      // Setup alarms
      this.setupAlarms(props);
    } else {
      // For non-production, create a simplified dashboard with basic metrics
      this.dashboard = new cloudwatch.Dashboard(this, 'Dashboard', {
        dashboardName: `finefinds-${props.environment}-dashboard`,
      });

      // Setup a simplified set of widgets
      this.setupSimplifiedDashboardWidgets(props);
      
      // Setup only critical alarms for non-production
      this.setupCriticalAlarms(props);
    }
  }

  private setupLogGroups(props: MonitoringConstructProps): void {
    // Create log groups with appropriate retention
    const retentionDays = props.environment === 'prod' ? 90 : 7;

    new logs.LogGroup(this, 'EcsLogGroup', {
      logGroupName: `/ecs/finefinds-${props.environment}`,
      retention: props.environment === 'prod' 
        ? logs.RetentionDays.THREE_MONTHS 
        : logs.RetentionDays.ONE_WEEK,
      removalPolicy: props.environment === 'prod' 
        ? cdk.RemovalPolicy.RETAIN 
        : cdk.RemovalPolicy.DESTROY,
    });

    new logs.LogGroup(this, 'ApplicationLogGroup', {
      logGroupName: `/finefinds/${props.environment}/application`,
      retention: props.environment === 'prod' 
        ? logs.RetentionDays.THREE_MONTHS 
        : logs.RetentionDays.ONE_WEEK,
      removalPolicy: props.environment === 'prod' 
        ? cdk.RemovalPolicy.RETAIN 
        : cdk.RemovalPolicy.DESTROY,
    });
  }

  private setupDashboardWidgets(props: MonitoringConstructProps): void {
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

  private setupSimplifiedDashboardWidgets(props: MonitoringConstructProps): void {
    // Basic compute metrics for non-production
    this.dashboard.addWidgets(
      new cloudwatch.GraphWidget({
        title: 'ECS CPU & Memory',
        left: [
          new cloudwatch.Metric({
            namespace: 'AWS/ECS',
            metricName: 'CPUUtilization',
            dimensionsMap: {
              ClusterName: `finefinds-${props.environment}-cluster`,
            },
            statistic: 'Average',
          }),
          new cloudwatch.Metric({
            namespace: 'AWS/ECS',
            metricName: 'MemoryUtilization',
            dimensionsMap: {
              ClusterName: `finefinds-${props.environment}-cluster`,
            },
            statistic: 'Average',
          }),
        ],
      })
    );

    // Basic database metrics
    this.dashboard.addWidgets(
      new cloudwatch.GraphWidget({
        title: 'Database',
        left: [
          new cloudwatch.Metric({
            namespace: 'AWS/RDS',
            metricName: 'CPUUtilization',
            dimensionsMap: {
              DBClusterIdentifier: `finefinds-${props.environment}-cluster`,
            },
            statistic: 'Average',
          }),
          new cloudwatch.Metric({
            namespace: 'AWS/RDS',
            metricName: 'FreeableMemory',
            dimensionsMap: {
              DBClusterIdentifier: `finefinds-${props.environment}-cluster`,
            },
            statistic: 'Average',
          }),
        ],
      })
    );
  }

  private setupAlarms(props: MonitoringConstructProps): void {
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

  private setupCriticalAlarms(props: MonitoringConstructProps): void {
    // Only critical alarms for non-production
    
    // ECS high CPU alarm (only alert if very high for extended period)
    new cloudwatch.Alarm(this, 'EcsCPUCritical', {
      metric: new cloudwatch.Metric({
        namespace: 'AWS/ECS',
        metricName: 'CPUUtilization',
        dimensionsMap: {
          ClusterName: `finefinds-${props.environment}-cluster`,
        },
        statistic: 'Average',
      }),
      threshold: 90,
      evaluationPeriods: 5,
      datapointsToAlarm: 5,
      alarmDescription: `Critical: ECS CPU above 90% for 5 minutes in ${props.environment}`,
      comparisonOperator: cloudwatch.ComparisonOperator.GREATER_THAN_THRESHOLD,
      treatMissingData: cloudwatch.TreatMissingData.NOT_BREACHING,
    });
    
    // Database critical alarm
    new cloudwatch.Alarm(this, 'DatabaseCPUCritical', {
      metric: new cloudwatch.Metric({
        namespace: 'AWS/RDS',
        metricName: 'CPUUtilization',
        dimensionsMap: {
          DBClusterIdentifier: `finefinds-${props.environment}-cluster`,
        },
        statistic: 'Average',
      }),
      threshold: 90,
      evaluationPeriods: 5,
      datapointsToAlarm: 5,
      alarmDescription: `Critical: Database CPU above 90% for 5 minutes in ${props.environment}`,
      comparisonOperator: cloudwatch.ComparisonOperator.GREATER_THAN_THRESHOLD,
      treatMissingData: cloudwatch.TreatMissingData.NOT_BREACHING,
    });
  }

  public get dashboardUrl(): string {
    return `https://${this.region}.console.aws.amazon.com/cloudwatch/home?region=${this.region}#dashboards:name=finefinds-${this.environment}-dashboard`;
  }
} 