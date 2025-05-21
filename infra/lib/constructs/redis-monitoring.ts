import * as cdk from 'aws-cdk-lib';
import * as cloudwatch from 'aws-cdk-lib/aws-cloudwatch';
import * as cloudwatch_actions from 'aws-cdk-lib/aws-cloudwatch-actions';
import * as sns from 'aws-cdk-lib/aws-sns';
import * as subscriptions from 'aws-cdk-lib/aws-sns-subscriptions';
import { Construct } from 'constructs';
import { BaseConfig } from '../../env/base-config';

export interface RedisMonitoringProps {
  environment: string;
  config: BaseConfig;
  clusterId: string;
  alarmTopic: sns.Topic;
}

export class RedisMonitoring extends Construct {
  constructor(scope: Construct, id: string, props: RedisMonitoringProps) {
    super(scope, id);

    // CPU Utilization Alarm
    new cloudwatch.Alarm(this, 'RedisCPUUtilizationAlarm', {
      metric: new cloudwatch.Metric({
        metricName: 'CPUUtilization',
        namespace: 'finefinds-elasticache',
        dimensionsMap: {
          CacheClusterId: props.clusterId,
        },
        statistic: 'Average',
        period: cdk.Duration.minutes(5),
      }),
      threshold: 75,
      evaluationPeriods: 3,
      datapointsToAlarm: 2,
      alarmDescription: 'Redis cluster CPU utilization is too high',
      alarmName: `finefinds-${props.environment}-redis-cpu-utilization`,
      comparisonOperator: cloudwatch.ComparisonOperator.GREATER_THAN_THRESHOLD,
      treatMissingData: cloudwatch.TreatMissingData.BREACHING,
    }).addAlarmAction(new cloudwatch_actions.SnsAction(props.alarmTopic));

    // Memory Alarm
    new cloudwatch.Alarm(this, 'RedisMemoryAlarm', {
      metric: new cloudwatch.Metric({
        metricName: 'DatabaseMemoryUsagePercentage',
        namespace: 'finefinds-elasticache',
        dimensionsMap: {
          CacheClusterId: props.clusterId,
        },
        statistic: 'Average',
        period: cdk.Duration.minutes(5),
      }),
      threshold: 80,
      evaluationPeriods: 3,
      datapointsToAlarm: 2,
      alarmDescription: 'Redis cluster memory usage is too high',
      alarmName: `finefinds-${props.environment}-redis-memory-usage`,
      comparisonOperator: cloudwatch.ComparisonOperator.GREATER_THAN_THRESHOLD,
      treatMissingData: cloudwatch.TreatMissingData.BREACHING,
    }).addAlarmAction(new cloudwatch_actions.SnsAction(props.alarmTopic));

    // Connection Count Alarm
    new cloudwatch.Alarm(this, 'RedisConnectionsAlarm', {
      metric: new cloudwatch.Metric({
        metricName: 'CurrConnections',
        namespace: 'finefinds-elasticache',
        dimensionsMap: {
          CacheClusterId: props.clusterId,
        },
        statistic: 'Maximum',
        period: cdk.Duration.minutes(5),
      }),
      threshold: 1000,
      evaluationPeriods: 3,
      datapointsToAlarm: 2,
      alarmDescription: 'Redis cluster connection count is too high',
      alarmName: `finefinds-${props.environment}-redis-connections`,
      comparisonOperator: cloudwatch.ComparisonOperator.GREATER_THAN_THRESHOLD,
      treatMissingData: cloudwatch.TreatMissingData.BREACHING,
    }).addAlarmAction(new cloudwatch_actions.SnsAction(props.alarmTopic));

    // Cache Hit Rate Alarm
    new cloudwatch.Alarm(this, 'RedisCacheHitRateAlarm', {
      metric: new cloudwatch.Metric({
        metricName: 'CacheHitRate',
        namespace: 'finefinds-elasticache',
        dimensionsMap: {
          CacheClusterId: props.clusterId,
        },
        statistic: 'Average',
        period: cdk.Duration.minutes(5),
      }),
      threshold: 0.8, // 80% hit rate
      evaluationPeriods: 3,
      datapointsToAlarm: 2,
      alarmDescription: 'Redis cluster cache hit rate is too low',
      alarmName: `finefinds-${props.environment}-redis-cache-hit-rate`,
      comparisonOperator: cloudwatch.ComparisonOperator.LESS_THAN_THRESHOLD,
      treatMissingData: cloudwatch.TreatMissingData.BREACHING,
    }).addAlarmAction(new cloudwatch_actions.SnsAction(props.alarmTopic));

    // Evictions Alarm
    new cloudwatch.Alarm(this, 'RedisEvictionsAlarm', {
      metric: new cloudwatch.Metric({
        metricName: 'Evictions',
        namespace: 'finefinds-elasticache',
        dimensionsMap: {
          CacheClusterId: props.clusterId,
        },
        statistic: 'Sum',
        period: cdk.Duration.minutes(5),
      }),
      threshold: 100,
      evaluationPeriods: 3,
      datapointsToAlarm: 2,
      alarmDescription: 'Redis cluster evictions are too high',
      alarmName: `finefinds-${props.environment}-redis-evictions`,
      comparisonOperator: cloudwatch.ComparisonOperator.GREATER_THAN_THRESHOLD,
      treatMissingData: cloudwatch.TreatMissingData.BREACHING,
    }).addAlarmAction(new cloudwatch_actions.SnsAction(props.alarmTopic));
  }
} 