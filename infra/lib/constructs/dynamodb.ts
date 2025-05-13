import * as cdk from 'aws-cdk-lib';
import * as dynamodb from 'aws-cdk-lib/aws-dynamodb';
import * as kms from 'aws-cdk-lib/aws-kms';
import { Construct } from 'constructs';
import { BaseConfig } from '../../env/base-config';

export interface DynamoDBConstructProps {
  environment: string;
  config: BaseConfig;
  kmsKey: kms.Key;
}

export class DynamoDBConstruct extends Construct {
  public readonly sessionsTable: dynamodb.Table;
  public readonly cacheTable: dynamodb.Table;

  constructor(scope: Construct, id: string, props: DynamoDBConstructProps) {
    super(scope, id);

    // Create Sessions Table - used for user session management
    this.sessionsTable = new dynamodb.Table(this, 'SessionsTable', {
      tableName: `finefinds-${props.environment}-sessions`,
      partitionKey: { name: 'sessionId', type: dynamodb.AttributeType.STRING },
      sortKey: { name: 'userId', type: dynamodb.AttributeType.STRING },
      timeToLiveAttribute: 'expiresAt',
      // Use on-demand billing for non-production environments to save costs
      billingMode: props.environment === 'prod'
        ? dynamodb.BillingMode.PROVISIONED
        : dynamodb.BillingMode.PAY_PER_REQUEST,
      // Only set provisioned capacity for production
      readCapacity: props.environment === 'prod' ? 5 : undefined,
      writeCapacity: props.environment === 'prod' ? 5 : undefined,
      // Enable point-in-time recovery only in production
      pointInTimeRecovery: props.environment === 'prod',
      // Enable server-side encryption with KMS
      encryption: dynamodb.TableEncryption.CUSTOMER_MANAGED,
      encryptionKey: props.kmsKey,
      // Use cost-optimized removal policy
      removalPolicy: props.environment === 'prod' 
        ? cdk.RemovalPolicy.RETAIN 
        : cdk.RemovalPolicy.DESTROY,
    });
    
    // Add TTL for sessions to automatically clean up old data
    if (props.environment !== 'prod') {
      // Add auto scaling only in production 
      // (on-demand is used in other environments)
      this.sessionsTable.autoScaleReadCapacity({
        minCapacity: 5,
        maxCapacity: 100,
      }).scaleOnUtilization({ targetUtilizationPercent: 70 });
      
      this.sessionsTable.autoScaleWriteCapacity({
        minCapacity: 5,
        maxCapacity: 50,
      }).scaleOnUtilization({ targetUtilizationPercent: 70 });
    }
    
    // Create Cache Table - used for application caching
    this.cacheTable = new dynamodb.Table(this, 'CacheTable', {
      tableName: `finefinds-${props.environment}-cache`,
      partitionKey: { name: 'cacheKey', type: dynamodb.AttributeType.STRING },
      timeToLiveAttribute: 'ttl',
      // Use on-demand billing for all environments for cache table
      // This is more cost-effective for unpredictable cache access patterns
      billingMode: dynamodb.BillingMode.PAY_PER_REQUEST,
      // No auto-scaling needed with on-demand billing
      // Enable point-in-time recovery only in production
      pointInTimeRecovery: false, // No need for this on a cache table
      // Enable server-side encryption with KMS
      encryption: dynamodb.TableEncryption.CUSTOMER_MANAGED,
      encryptionKey: props.kmsKey,
      // Always use DESTROY for cache tables
      removalPolicy: cdk.RemovalPolicy.DESTROY,
    });
    
    // Outputs
    new cdk.CfnOutput(this, 'SessionsTableName', {
      value: this.sessionsTable.tableName,
      description: 'DynamoDB Sessions Table Name',
      exportName: `finefinds-${props.environment}-sessions-table`,
    });
    
    new cdk.CfnOutput(this, 'CacheTableName', {
      value: this.cacheTable.tableName,
      description: 'DynamoDB Cache Table Name',
      exportName: `finefinds-${props.environment}-cache-table`,
    });
  }
} 