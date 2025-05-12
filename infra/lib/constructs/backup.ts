import * as cdk from 'aws-cdk-lib';
import * as backup from 'aws-cdk-lib/aws-backup';
import * as iam from 'aws-cdk-lib/aws-iam';
import * as events from 'aws-cdk-lib/aws-events';
import { Construct } from 'constructs';
import { BaseConfig } from '../../env/base-config';

export interface BackupConstructProps {
  environment: string;
  config: BaseConfig;
}

export class BackupConstruct extends Construct {
  public readonly vault: backup.BackupVault;
  public readonly plan: backup.BackupPlan;

  constructor(scope: Construct, id: string, props: BackupConstructProps) {
    super(scope, id);

    // Create backup vault
    this.vault = new backup.BackupVault(this, 'Vault', {
      backupVaultName: `finefinds-${props.environment}-backup-vault`,
      removalPolicy: props.environment === 'prod' 
        ? cdk.RemovalPolicy.RETAIN 
        : cdk.RemovalPolicy.DESTROY,
      encryptionKey: undefined, // Uses AWS managed key
    });

    // Create backup plan
    this.plan = new backup.BackupPlan(this, 'Plan', {
      backupPlanName: `finefinds-${props.environment}-backup-plan`,
      backupVault: this.vault,
    });

    // Add backup rules based on environment
    if (props.environment === 'prod') {
      // Daily backups for 30 days
      this.plan.addRule(new backup.BackupPlanRule({
        completionWindow: cdk.Duration.hours(2),
        startWindow: cdk.Duration.hours(1),
        scheduleExpression: events.Schedule.cron({
          minute: '0',
          hour: '5',
          day: '*',
          month: '*',
          year: '*',
        }),
        deleteAfter: cdk.Duration.days(30),
      }));

      // Weekly backups for 3 months
      this.plan.addRule(new backup.BackupPlanRule({
        completionWindow: cdk.Duration.hours(2),
        startWindow: cdk.Duration.hours(1),
        scheduleExpression: events.Schedule.cron({
          minute: '0',
          hour: '5',
          day: '1',
          month: '*',
          year: '*',
        }),
        deleteAfter: cdk.Duration.days(90),
      }));

      // Monthly backups for 1 year
      this.plan.addRule(new backup.BackupPlanRule({
        completionWindow: cdk.Duration.hours(2),
        startWindow: cdk.Duration.hours(1),
        scheduleExpression: events.Schedule.cron({
          minute: '0',
          hour: '5',
          day: '1',
          month: '1',
          year: '*',
        }),
        deleteAfter: cdk.Duration.days(365),
      }));
    } else {
      // Daily backups for 7 days in non-prod environments
      this.plan.addRule(new backup.BackupPlanRule({
        completionWindow: cdk.Duration.hours(2),
        startWindow: cdk.Duration.hours(1),
        scheduleExpression: events.Schedule.cron({
          minute: '0',
          hour: '5',
          day: '*',
          month: '*',
          year: '*',
        }),
        deleteAfter: cdk.Duration.days(7),
      }));
    }

    // Add selection for resources to backup
    this.plan.addSelection('Selection', {
      resources: [
        backup.BackupResource.fromTag('Environment', props.environment),
        backup.BackupResource.fromTag('Project', 'FineFinds'),
      ],
    });

    // Output vault ARN
    new cdk.CfnOutput(this, 'VaultArn', {
      value: this.vault.backupVaultArn,
      description: 'Backup Vault ARN',
      exportName: `finefinds-${props.environment}-backup-vault-arn`,
    });

    // Output plan ARN
    new cdk.CfnOutput(this, 'PlanArn', {
      value: this.plan.backupPlanArn,
      description: 'Backup Plan ARN',
      exportName: `finefinds-${props.environment}-backup-plan-arn`,
    });
  }
} 