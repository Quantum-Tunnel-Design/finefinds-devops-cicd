import * as cdk from 'aws-cdk-lib';
import * as logs from 'aws-cdk-lib/aws-logs';
import * as iam from 'aws-cdk-lib/aws-iam';
import * as kms from 'aws-cdk-lib/aws-kms';
import { Construct } from 'constructs';
import { BaseConfig } from '../../env/base-config';

export interface LogsConstructProps {
  environment: string;
  config: BaseConfig;
  kmsKey: kms.Key;
}

export class LogsConstruct extends Construct {
  public readonly applicationLogGroup: logs.LogGroup;
  public readonly accessLogGroup: logs.LogGroup;
  public readonly errorLogGroup: logs.LogGroup;
  public readonly auditLogGroup: logs.LogGroup;

  constructor(scope: Construct, id: string, props: LogsConstructProps) {
    super(scope, id);

    // Create application log group
    this.applicationLogGroup = new logs.LogGroup(this, 'ApplicationLogGroup', {
      logGroupName: `finefinds-${props.environment}-application-logs`,
      retention: props.environment === 'prod' ? logs.RetentionDays.ONE_MONTH : logs.RetentionDays.ONE_WEEK,
      encryptionKey: props.kmsKey,
      removalPolicy: props.environment === 'prod' ? cdk.RemovalPolicy.RETAIN : cdk.RemovalPolicy.DESTROY,
    });

    // Create access log group
    this.accessLogGroup = new logs.LogGroup(this, 'AccessLogGroup', {
      logGroupName: `finefinds-${props.environment}-access-logs`,
      retention: props.environment === 'prod' ? logs.RetentionDays.ONE_MONTH : logs.RetentionDays.ONE_WEEK,
      encryptionKey: props.kmsKey,
      removalPolicy: props.environment === 'prod' ? cdk.RemovalPolicy.RETAIN : cdk.RemovalPolicy.DESTROY,
    });

    // Create error log group
    this.errorLogGroup = new logs.LogGroup(this, 'ErrorLogGroup', {
      logGroupName: `finefinds-${props.environment}-error-logs`,
      retention: props.environment === 'prod' ? logs.RetentionDays.ONE_MONTH : logs.RetentionDays.ONE_WEEK,
      encryptionKey: props.kmsKey,
      removalPolicy: props.environment === 'prod' ? cdk.RemovalPolicy.RETAIN : cdk.RemovalPolicy.DESTROY,
    });

    // Create audit log group
    this.auditLogGroup = new logs.LogGroup(this, 'AuditLogGroup', {
      logGroupName: `finefinds-${props.environment}-audit-logs`,
      retention: props.environment === 'prod' ? logs.RetentionDays.ONE_MONTH : logs.RetentionDays.ONE_WEEK,
      encryptionKey: props.kmsKey,
      removalPolicy: props.environment === 'prod' ? cdk.RemovalPolicy.RETAIN : cdk.RemovalPolicy.DESTROY,
    });

    // Create metric filters for error logs
    this.errorLogGroup.addMetricFilter('ErrorCount', {
      metricName: 'ErrorCount',
      metricNamespace: `finefinds-${props.environment}`,
      filterPattern: logs.FilterPattern.stringValue('$.level', '=', 'ERROR'),
      metricValue: '1',
    });

    this.errorLogGroup.addMetricFilter('WarningCount', {
      metricName: 'WarningCount',
      metricNamespace: `finefinds-${props.environment}`,
      filterPattern: logs.FilterPattern.stringValue('$.level', '=', 'WARN'),
      metricValue: '1',
    });

    // Create metric filters for access logs
    this.accessLogGroup.addMetricFilter('RequestCount', {
      metricName: 'RequestCount',
      metricNamespace: `finefinds-${props.environment}`,
      filterPattern: logs.FilterPattern.exists('$.request'),
      metricValue: '1',
    });

    this.accessLogGroup.addMetricFilter('ResponseTime', {
      metricName: 'ResponseTime',
      metricNamespace: `finefinds-${props.environment}`,
      filterPattern: logs.FilterPattern.exists('$.responseTime'),
      metricValue: '$.responseTime',
    });

    // Create IAM policy for ECS tasks to write logs
    const logPolicy = new iam.PolicyStatement({
      effect: iam.Effect.ALLOW,
      actions: [
        'logs:CreateLogGroup',
        'logs:CreateLogStream',
        'logs:PutLogEvents',
        'logs:DescribeLogStreams',
      ],
      resources: [
        this.applicationLogGroup.logGroupArn,
        this.accessLogGroup.logGroupArn,
        this.errorLogGroup.logGroupArn,
        this.auditLogGroup.logGroupArn,
      ],
    });

    // Output log group ARNs
    new cdk.CfnOutput(this, 'ApplicationLogGroupArn', {
      value: this.applicationLogGroup.logGroupArn,
      description: 'Application Log Group ARN',
      exportName: `finefinds-${props.environment}-application-log-group-arn`,
    });

    new cdk.CfnOutput(this, 'AccessLogGroupArn', {
      value: this.accessLogGroup.logGroupArn,
      description: 'Access Log Group ARN',
      exportName: `finefinds-${props.environment}-access-log-group-arn`,
    });

    new cdk.CfnOutput(this, 'ErrorLogGroupArn', {
      value: this.errorLogGroup.logGroupArn,
      description: 'Error Log Group ARN',
      exportName: `finefinds-${props.environment}-error-log-group-arn`,
    });

    new cdk.CfnOutput(this, 'AuditLogGroupArn', {
      value: this.auditLogGroup.logGroupArn,
      description: 'Audit Log Group ARN',
      exportName: `finefinds-${props.environment}-audit-log-group-arn`,
    });
  }
} 