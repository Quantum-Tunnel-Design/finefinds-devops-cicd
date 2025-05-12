import * as cdk from 'aws-cdk-lib';
import * as iam from 'aws-cdk-lib/aws-iam';
import { Construct } from 'constructs';
import { BaseConfig } from '../../env/base-config';

export interface IamConstructProps {
  environment: string;
  config: BaseConfig;
}

export class IamConstruct extends Construct {
  public readonly ecsTaskRole: iam.Role;
  public readonly ecsExecutionRole: iam.Role;
  public readonly backupRole: iam.Role;
  public readonly monitoringRole: iam.Role;

  constructor(scope: Construct, id: string, props: IamConstructProps) {
    super(scope, id);

    // Create ECS Task Role
    this.ecsTaskRole = new iam.Role(this, 'EcsTaskRole', {
      roleName: `finefinds-${props.environment}-ecs-task-role`,
      assumedBy: new iam.ServicePrincipal('ecs-tasks.amazonaws.com'),
      managedPolicies: [
        iam.ManagedPolicy.fromAwsManagedPolicyName('AmazonS3ReadOnlyAccess'),
        iam.ManagedPolicy.fromAwsManagedPolicyName('CloudWatchLogsFullAccess'),
        iam.ManagedPolicy.fromAwsManagedPolicyName('AWSXRayDaemonWriteAccess'),
      ],
    });

    // Add custom policies for ECS Task Role
    this.ecsTaskRole.addToPolicy(
      new iam.PolicyStatement({
        effect: iam.Effect.ALLOW,
        actions: [
          'ecr:GetAuthorizationToken',
          'ecr:BatchCheckLayerAvailability',
          'ecr:GetDownloadUrlForLayer',
          'ecr:BatchGetImage',
        ],
        resources: ['*'],
      })
    );

    // Create ECS Execution Role
    this.ecsExecutionRole = new iam.Role(this, 'EcsExecutionRole', {
      roleName: `finefinds-${props.environment}-ecs-execution-role`,
      assumedBy: new iam.ServicePrincipal('ecs-tasks.amazonaws.com'),
      managedPolicies: [
        iam.ManagedPolicy.fromAwsManagedPolicyName('AmazonECSTaskExecutionRolePolicy'),
      ],
    });

    // Create Backup Role
    this.backupRole = new iam.Role(this, 'BackupRole', {
      roleName: `finefinds-${props.environment}-backup-role`,
      assumedBy: new iam.ServicePrincipal('backup.amazonaws.com'),
      managedPolicies: [
        iam.ManagedPolicy.fromAwsManagedPolicyName('AWSBackupServiceRolePolicyForBackup'),
        iam.ManagedPolicy.fromAwsManagedPolicyName('AWSBackupServiceRolePolicyForRestores'),
      ],
    });

    // Create Monitoring Role
    this.monitoringRole = new iam.Role(this, 'MonitoringRole', {
      roleName: `finefinds-${props.environment}-monitoring-role`,
      assumedBy: new iam.ServicePrincipal('monitoring.rds.amazonaws.com'),
      managedPolicies: [
        iam.ManagedPolicy.fromAwsManagedPolicyName('CloudWatchAgentServerPolicy'),
      ],
    });

    // Add custom policies for Monitoring Role
    this.monitoringRole.addToPolicy(
      new iam.PolicyStatement({
        effect: iam.Effect.ALLOW,
        actions: [
          'cloudwatch:PutMetricData',
          'ec2:DescribeVolumes',
          'ec2:DescribeTags',
          'logs:PutLogEvents',
          'logs:DescribeLogStreams',
          'logs:DescribeLogGroups',
          'logs:CreateLogStream',
          'logs:CreateLogGroup',
        ],
        resources: ['*'],
      })
    );

    // Create IAM Group for Developers
    const developerGroup = new iam.Group(this, 'DeveloperGroup', {
      groupName: `finefinds-${props.environment}-developers`,
    });

    // Add policies to Developer Group
    developerGroup.addManagedPolicy(
      iam.ManagedPolicy.fromAwsManagedPolicyName('AWSCloudFormationReadOnlyAccess')
    );
    developerGroup.addManagedPolicy(
      iam.ManagedPolicy.fromAwsManagedPolicyName('AmazonECR-FullAccess')
    );
    developerGroup.addManagedPolicy(
      iam.ManagedPolicy.fromAwsManagedPolicyName('AmazonECS-FullAccess')
    );

    // Create IAM Group for DevOps
    const devOpsGroup = new iam.Group(this, 'DevOpsGroup', {
      groupName: `finefinds-${props.environment}-devops`,
    });

    // Add policies to DevOps Group
    devOpsGroup.addManagedPolicy(
      iam.ManagedPolicy.fromAwsManagedPolicyName('AdministratorAccess')
    );

    // Output role ARNs
    new cdk.CfnOutput(this, 'EcsTaskRoleArn', {
      value: this.ecsTaskRole.roleArn,
      description: 'ECS Task Role ARN',
      exportName: `finefinds-${props.environment}-ecs-task-role-arn`,
    });

    new cdk.CfnOutput(this, 'EcsExecutionRoleArn', {
      value: this.ecsExecutionRole.roleArn,
      description: 'ECS Execution Role ARN',
      exportName: `finefinds-${props.environment}-ecs-execution-role-arn`,
    });

    new cdk.CfnOutput(this, 'BackupRoleArn', {
      value: this.backupRole.roleArn,
      description: 'Backup Role ARN',
      exportName: `finefinds-${props.environment}-backup-role-arn`,
    });

    new cdk.CfnOutput(this, 'MonitoringRoleArn', {
      value: this.monitoringRole.roleArn,
      description: 'Monitoring Role ARN',
      exportName: `finefinds-${props.environment}-monitoring-role-arn`,
    });
  }
} 