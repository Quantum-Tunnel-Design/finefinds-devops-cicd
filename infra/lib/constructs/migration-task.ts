import * as cdk from 'aws-cdk-lib';
import * as ecs from 'aws-cdk-lib/aws-ecs';
import * as ec2 from 'aws-cdk-lib/aws-ec2';
import * as logs from 'aws-cdk-lib/aws-logs';
import * as iam from 'aws-cdk-lib/aws-iam';
import * as ecr from 'aws-cdk-lib/aws-ecr';
import { Construct } from 'constructs';
import { BaseConfig } from '../../env/base-config';

export interface MigrationTaskConstructProps {
  environment: string;
  config: BaseConfig;
  vpc: ec2.Vpc;
  taskRole?: iam.IRole;
  executionRole?: iam.IRole;
}

export class MigrationTaskConstruct extends Construct {
  public readonly taskDefinition: ecs.FargateTaskDefinition;

  constructor(scope: Construct, id: string, props: MigrationTaskConstructProps) {
    super(scope, id);

    // Create task definition for migrations
    this.taskDefinition = new ecs.FargateTaskDefinition(this, 'MigrationTaskDef', {
      memoryLimitMiB: 512,
      cpu: 256,
      taskRole: props.taskRole,
      executionRole: props.executionRole,
      family: 'finefinds-backend-migration',
    });

    // Add container to task definition
    this.taskDefinition.addContainer('MigrationContainer', {
      image: ecs.ContainerImage.fromEcrRepository(
        ecr.Repository.fromRepositoryAttributes(this, 'ECRRepo', {
          repositoryArn: `arn:aws:ecr:${cdk.Stack.of(this).region}:${cdk.Stack.of(this).account}:repository/${props.config.ecr.repositoryName}`,
          repositoryName: props.config.ecr.repositoryName,
        }),
        'latest'
      ),
      logging: ecs.LogDrivers.awsLogs({
        streamPrefix: 'migration',
        logGroup: new logs.LogGroup(this, 'MigrationLogGroup', {
          logGroupName: `/finefinds/${props.environment}/migration`,
          retention: props.environment === 'prod' 
            ? logs.RetentionDays.ONE_MONTH 
            : logs.RetentionDays.ONE_DAY,
          removalPolicy: props.environment === 'prod' 
            ? cdk.RemovalPolicy.RETAIN 
            : cdk.RemovalPolicy.DESTROY,
        }),
      }),
      command: ['npx', 'prisma', 'migrate', 'deploy'],
      environment: {
        NODE_ENV: props.environment,
      },
      secrets: {
        DATABASE_URL: ecs.Secret.fromSecretsManager(
          cdk.aws_secretsmanager.Secret.fromSecretNameV2(
            this,
            'DbConnectionSecret',
            `finefinds-${props.environment}-rds-connection`
          )
        ),
      },
    });

    // Output the task definition ARN
    new cdk.CfnOutput(this, 'MigrationTaskDefinitionArn', {
      value: this.taskDefinition.taskDefinitionArn,
      description: 'ARN of the migration task definition',
      exportName: `finefinds-${props.environment}-migration-task-definition-arn`,
    });
  }
} 