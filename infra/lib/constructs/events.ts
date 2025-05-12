import * as cdk from 'aws-cdk-lib';
import * as events from 'aws-cdk-lib/aws-events';
import * as targets from 'aws-cdk-lib/aws-events-targets';
import * as lambda from 'aws-cdk-lib/aws-lambda';
import * as iam from 'aws-cdk-lib/aws-iam';
import { Construct } from 'constructs';
import { BaseConfig } from '../../env/base-config';

export interface EventsConstructProps {
  environment: string;
  config: BaseConfig;
}

export class EventsConstruct extends Construct {
  public readonly eventBus: events.EventBus;
  public readonly backupRule: events.Rule;
  public readonly cleanupRule: events.Rule;
  public readonly metricsRule: events.Rule;

  constructor(scope: Construct, id: string, props: EventsConstructProps) {
    super(scope, id);

    // Create custom event bus
    this.eventBus = new events.EventBus(this, 'EventBus', {
      eventBusName: `finefinds-${props.environment}-bus`,
    });

    // Create backup Lambda function
    const backupFunction = new lambda.Function(this, 'BackupFunction', {
      runtime: lambda.Runtime.NODEJS_18_X,
      handler: 'index.handler',
      code: lambda.Code.fromAsset('lambda/backup'),
      environment: {
        ENVIRONMENT: props.environment,
      },
      timeout: cdk.Duration.minutes(5),
      memorySize: 256,
    });

    // Add backup permissions to Lambda function
    backupFunction.addToRolePolicy(
      new iam.PolicyStatement({
        effect: iam.Effect.ALLOW,
        actions: [
          'backup:StartBackupJob',
          'backup:StopBackupJob',
          'backup:PutBackupVaultAccessPolicy',
          'backup:GetBackupVaultAccessPolicy',
          'backup:DeleteBackupVaultAccessPolicy',
          'backup:DeleteBackupVault',
          'backup:DeleteBackupPlan',
          'backup:CreateBackupPlan',
          'backup:CreateBackupVault',
        ],
        resources: ['*'],
      })
    );

    // Create cleanup Lambda function
    const cleanupFunction = new lambda.Function(this, 'CleanupFunction', {
      runtime: lambda.Runtime.NODEJS_18_X,
      handler: 'index.handler',
      code: lambda.Code.fromAsset('lambda/cleanup'),
      environment: {
        ENVIRONMENT: props.environment,
      },
      timeout: cdk.Duration.minutes(5),
      memorySize: 256,
    });

    // Add cleanup permissions to Lambda function
    cleanupFunction.addToRolePolicy(
      new iam.PolicyStatement({
        effect: iam.Effect.ALLOW,
        actions: [
          's3:ListBucket',
          's3:DeleteObject',
          'logs:DeleteLogGroup',
          'logs:DeleteLogStream',
        ],
        resources: ['*'],
      })
    );

    // Create metrics Lambda function
    const metricsFunction = new lambda.Function(this, 'MetricsFunction', {
      runtime: lambda.Runtime.NODEJS_18_X,
      handler: 'index.handler',
      code: lambda.Code.fromAsset('lambda/metrics'),
      environment: {
        ENVIRONMENT: props.environment,
      },
      timeout: cdk.Duration.minutes(5),
      memorySize: 256,
    });

    // Add metrics permissions to Lambda function
    metricsFunction.addToRolePolicy(
      new iam.PolicyStatement({
        effect: iam.Effect.ALLOW,
        actions: [
          'cloudwatch:PutMetricData',
          'cloudwatch:GetMetricStatistics',
          'cloudwatch:ListMetrics',
        ],
        resources: ['*'],
      })
    );

    // Create backup rule
    this.backupRule = new events.Rule(this, 'BackupRule', {
      schedule: events.Schedule.cron({
        minute: '0',
        hour: '0',
        day: '*',
        month: '*',
        year: '*',
      }),
      targets: [new targets.LambdaFunction(backupFunction)],
    });

    // Create cleanup rule
    this.cleanupRule = new events.Rule(this, 'CleanupRule', {
      schedule: events.Schedule.cron({
        minute: '0',
        hour: '1',
        day: '*',
        month: '*',
        year: '*',
      }),
      targets: [new targets.LambdaFunction(cleanupFunction)],
    });

    // Create metrics rule
    this.metricsRule = new events.Rule(this, 'MetricsRule', {
      schedule: events.Schedule.cron({
        minute: '*/5',
        hour: '*',
        day: '*',
        month: '*',
        year: '*',
      }),
      targets: [new targets.LambdaFunction(metricsFunction)],
    });

    // Output event bus ARN
    new cdk.CfnOutput(this, 'EventBusArn', {
      value: this.eventBus.eventBusArn,
      description: 'Event Bus ARN',
      exportName: `finefinds-${props.environment}-event-bus-arn`,
    });
  }
} 