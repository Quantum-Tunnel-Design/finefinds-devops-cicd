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
  public readonly vault?: backup.BackupVault;
  public readonly plan?: backup.BackupPlan;

  constructor(scope: Construct, id: string, props: BackupConstructProps) {
    super(scope, id);

    // Only create backup resources in production
    if (props.environment === 'prod') {
      // Create backup vault
      this.vault = new backup.BackupVault(this, 'Vault', {
        backupVaultName: `finefinds-${props.environment}-backup-vault-${cdk.Stack.of(this).account}`,
        removalPolicy: cdk.RemovalPolicy.RETAIN,
        encryptionKey: undefined, // Uses AWS managed key
      });

      // Create backup plan
      this.plan = new backup.BackupPlan(this, 'Plan', {
        backupPlanName: `finefinds-${props.environment}-backup-plan`,
        backupVault: this.vault,
      });

      // Add backup rules for production
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

      // Add selection for resources to backup
      this.plan.addSelection('Selection', {
        resources: [
          backup.BackupResource.fromTag('Environment', props.environment),
          backup.BackupResource.fromTag('Project', 'finefinds'),
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
} 