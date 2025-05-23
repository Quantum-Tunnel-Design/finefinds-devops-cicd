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
    });

    // Add permissions for ECS Task Role using inline policy instead of managed policies
    this.ecsTaskRole.addToPolicy(
      new iam.PolicyStatement({
        effect: iam.Effect.ALLOW,
        actions: [
          // S3 Read Access
          's3:Get*',
          's3:List*',
          // CloudWatch Logs Access
          'logs:CreateLogGroup',
          'logs:CreateLogStream',
          'logs:PutLogEvents',
          'logs:DescribeLogStreams',
          // X-Ray Access
          'xray:PutTraceSegments',
          'xray:PutTelemetryRecords',
          'xray:GetSamplingRules',
          'xray:GetSamplingTargets',
          'xray:GetSamplingStatisticSummaries',
          'secretsmanager:GetSecretValue', // Broad permission restored
        ],
        resources: ['*'],
      })
    );

    // Comment out specific RDS policy again
    // this.ecsTaskRole.addToPolicy(
    //   new iam.PolicyStatement({
    //     effect: iam.Effect.ALLOW,
    //     actions: [
    //       'secretsmanager:GetSecretValue',
    //     ],
    //     resources: [
    //       `arn:aws:secretsmanager:${cdk.Stack.of(this).region}:${cdk.Stack.of(this).account}:secret:finefinds-${props.environment}-rds-connection-*`,
    //     ],
    //   })
    // );

    // Add specific ECR permissions with explicit cross-account access
    this.ecsTaskRole.addToPolicy(
      new iam.PolicyStatement({
        effect: iam.Effect.ALLOW,
        actions: [
          'ecr:GetAuthorizationToken',
        ],
        resources: ['*'], // Authorization token requires permissions on *
      })
    );

    // Add permissions for specific repositories
    this.ecsTaskRole.addToPolicy(
      new iam.PolicyStatement({
        effect: iam.Effect.ALLOW,
        actions: [
          'ecr:BatchCheckLayerAvailability',
          'ecr:GetDownloadUrlForLayer',
          'ecr:BatchGetImage',
        ],
        resources: [
          'arn:aws:ecr:us-east-1:891076991993:repository/finefinds-base/node-20-alpha',
          'arn:aws:ecr:us-east-1:891076991993:repository/finefinds-base/sonarqube',
          // Add permission for the finefinds-services-dev repository
          cdk.Arn.format({
            service: 'ecr',
            resource: 'repository',
            resourceName: `finefinds-services-${props.environment}`,
            // account and region will be implicitly picked from the stack
          }, cdk.Stack.of(this)),
        ],
      })
    );

    // Create ECS Execution Role
    this.ecsExecutionRole = new iam.Role(this, 'EcsExecutionRole', {
      roleName: `finefinds-${props.environment}-ecs-execution-role`,
      assumedBy: new iam.ServicePrincipal('ecs-tasks.amazonaws.com'),
    });

    // Add ECS execution policy with basic permissions
    this.ecsExecutionRole.addToPolicy(
      new iam.PolicyStatement({
        effect: iam.Effect.ALLOW,
        actions: [
          'logs:CreateLogStream',
          'logs:PutLogEvents',
          'secretsmanager:GetSecretValue',
          'ssm:GetParameters',
          'kms:Decrypt'
        ],
        resources: ['*'],
      })
    );

    // Add global ECR auth permission (needs to be on * resource)
    this.ecsExecutionRole.addToPolicy(
      new iam.PolicyStatement({
        effect: iam.Effect.ALLOW,
        actions: [
          'ecr:GetAuthorizationToken',
        ],
        resources: ['*'],
      })
    );

    // Add specific ECR repository permissions for ECS Execution Role
    this.ecsExecutionRole.addToPolicy(
      new iam.PolicyStatement({
        effect: iam.Effect.ALLOW,
        actions: [
          'ecr:BatchCheckLayerAvailability',
          'ecr:GetDownloadUrlForLayer',
          'ecr:BatchGetImage',
        ],
        resources: [
          'arn:aws:ecr:us-east-1:891076991993:repository/finefinds-base/node-20-alpha',
          'arn:aws:ecr:us-east-1:891076991993:repository/finefinds-base/sonarqube',
          // Add permission for the finefinds-services-dev repository
          cdk.Arn.format({
            service: 'ecr',
            resource: 'repository',
            resourceName: `finefinds-services-${props.environment}`,
            // account and region will be implicitly picked from the stack
          }, cdk.Stack.of(this)),
        ],
      })
    );

    // Create Backup Role
    this.backupRole = new iam.Role(this, 'BackupRole', {
      roleName: `finefinds-${props.environment}-backup-role`,
      assumedBy: new iam.ServicePrincipal('backup.amazonaws.com'),
    });
    
    // Add backup service policy
    this.backupRole.addToPolicy(
      new iam.PolicyStatement({
        effect: iam.Effect.ALLOW,
        actions: [
          'backup:*',
          'rds:DescribeDBInstances',
          'rds:CreateDBSnapshot',
          'rds:DeleteDBSnapshot',
          'rds:DescribeDBSnapshots',
          'rds:RestoreDBInstanceFromDBSnapshot',
          'ec2:CreateTags',
          'ec2:DeleteTags',
          'tag:GetResources',
          's3:CreateBucket',
          's3:ListBucket',
          's3:GetBucketAcl',
          's3:PutBucketAcl',
          's3:GetObject',
          's3:PutObject',
          's3:DeleteObject',
          's3:GetObjectAcl',
          's3:PutObjectAcl',
          's3:GetObjectVersionAcl',
          's3:PutObjectVersionAcl',
          's3:DeleteObjectVersion',
          'dynamodb:Scan',
          'dynamodb:Query',
          'dynamodb:ListTables',
          'dynamodb:DescribeTable',
          'dynamodb:GetItem',
          'dynamodb:PutItem',
          'dynamodb:UpdateItem',
          'dynamodb:DeleteItem',
          'dynamodb:BatchGetItem',
          'dynamodb:BatchWriteItem',
          'dynamodb:ListTagsOfResource'
        ],
        resources: ['*'],
      })
    );

    // Create Monitoring Role
    this.monitoringRole = new iam.Role(this, 'MonitoringRole', {
      roleName: `finefinds-${props.environment}-monitoring-role`,
      assumedBy: new iam.ServicePrincipal('monitoring.rds.amazonaws.com'),
    });

    // Add permissions for the Monitoring Role instead of using CloudWatchAgentServerPolicy
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
          'ssm:GetParameter',
          'ssm:PutParameter',
          'ssm:ListTagsForResource'
        ],
        resources: ['*'],
      })
    );

    // Create IAM Group for Developers
    const developerGroup = new iam.Group(this, 'DeveloperGroup', {
      groupName: `finefinds-${props.environment}-developers`,
    });

    // Add CloudFormation readonly permissions to Developer Group
    developerGroup.addToPolicy(
      new iam.PolicyStatement({
        effect: iam.Effect.ALLOW,
        actions: [
          'cloudformation:DescribeStacks',
          'cloudformation:DescribeStackEvents',
          'cloudformation:DescribeStackResource',
          'cloudformation:DescribeStackResources',
          'cloudformation:GetTemplate',
          'cloudformation:List*',
        ],
        resources: ['*'],
      })
    );

    // Add ECR permissions
    developerGroup.addToPolicy(
      new iam.PolicyStatement({
        effect: iam.Effect.ALLOW,
        actions: [
          'ecr:*',
        ],
        resources: ['*'],
      })
    );

    // Add back ECS permissions
    developerGroup.addToPolicy(
      new iam.PolicyStatement({
        effect: iam.Effect.ALLOW,
        actions: [
          'ecs:*',
          'elasticloadbalancing:*',
          'ec2:*',
          'cloudwatch:*',
          'application-autoscaling:*',
          'logs:*',
          'iam:PassRole'
        ],
        resources: ['*'],
      })
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