import * as cdk from 'aws-cdk-lib';
import * as ec2 from 'aws-cdk-lib/aws-ec2';
import * as rds from 'aws-cdk-lib/aws-rds';
import * as s3 from 'aws-cdk-lib/aws-s3';
import * as iam from 'aws-cdk-lib/aws-iam';
import { Construct } from 'constructs';
import { BaseConfig } from '../../env/base-config';

export interface ExistingConstructProps {
  environment: string;
  config: BaseConfig;
}

export class ExistingConstruct extends Construct {
  public readonly vpc: ec2.IVpc;
  public readonly database: rds.IDatabaseInstance;
  public readonly mediaBucket: s3.IBucket;

  constructor(scope: Construct, id: string, props: ExistingConstructProps) {
    super(scope, id);

    // Import existing VPC
    this.vpc = ec2.Vpc.fromLookup(this, 'Vpc', {
      vpcName: `finefinds-${props.environment}-vpc`,
    });

    // Import existing RDS instance
    this.database = rds.DatabaseInstance.fromDatabaseInstanceAttributes(
      this,
      'Database',
      {
        instanceEndpointAddress: cdk.Fn.importValue(
          `finefinds-${props.environment}-db-endpoint`
        ),
        port: 5432,
        securityGroups: [
          ec2.SecurityGroup.fromSecurityGroupId(
            this,
            'DbSecurityGroup',
            cdk.Fn.importValue(`finefinds-${props.environment}-db-sg-id`)
          ),
        ],
        instanceIdentifier: `finefinds-${props.environment}-db`,
      }
    );

    // Import existing media bucket
    this.mediaBucket = s3.Bucket.fromBucketName(
      this,
      'MediaBucket',
      `finefinds-${props.environment}-media`
    );

    // Output imported resource information
    new cdk.CfnOutput(this, 'VpcId', {
      value: this.vpc.vpcId,
      description: 'Imported VPC ID',
      exportName: `finefinds-${props.environment}-vpc-id`,
    });

    new cdk.CfnOutput(this, 'DatabaseEndpoint', {
      value: this.database.instanceEndpoint.hostname,
      description: 'Imported Database Endpoint',
      exportName: `finefinds-${props.environment}-imported-db-endpoint`,
    });

    new cdk.CfnOutput(this, 'MediaBucketName', {
      value: this.mediaBucket.bucketName,
      description: 'Imported Media Bucket Name',
      exportName: `finefinds-${props.environment}-media-bucket-name`,
    });
  }
} 